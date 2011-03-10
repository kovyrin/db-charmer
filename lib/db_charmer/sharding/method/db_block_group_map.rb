# This is a more sophisticated sharding method based on a two layer database-backed
# blocks map that holds block-shard associations. Record blocks are mapped to tablegroups
# and groups are mapped to shards.
#
# It automatically creates new blocks for new keys and assigns them to existing groups.
# Warning: make sure to create at least one shard and one group before inserting any records.
#
module DbCharmer
  module Sharding
    module Method
      class DbBlockGroupMap
        # Shard connection info model
        class Shard < ActiveRecord::Base
          validates_presence_of :db_host
          validates_presence_of :db_port
          validates_presence_of :db_user
          validates_presence_of :db_pass
          validates_presence_of :db_name_prefix

          has_many :groups, :class_name => 'DbCharmer::Sharding::Method::DbBlockGroupMap::Group'
        end

        # Table group info model
        class Group < ActiveRecord::Base
          validates_presence_of :shard_id
          belongs_to :shard, :class_name => 'DbCharmer::Sharding::Method::DbBlockGroupMap::Shard'
        end

        #---------------------------------------------------------------------------------------------------------------
        # Sharder name
        attr_accessor :name

        # Mapping db connection
        attr_accessor :connection, :connection_name

        # Mapping table name
        attr_accessor :map_table

        # Tablegroups table name
        attr_accessor :groups_table

        # Shards table name
        attr_accessor :shards_table

        # Sharding keys block size
        attr_accessor :block_size

        def initialize(config)
          @name = config[:name] or raise(ArgumentError, "Missing required :name parameter!")
          @connection = DbCharmer::ConnectionFactory.connect(config[:connection], true)
          @block_size = (config[:block_size] || 10000).to_i

          @map_table = config[:map_table] or raise(ArgumentError, "Missing required :map_table parameter!")
          @groups_table = config[:groups_table] or raise(ArgumentError, "Missing required :groups_table parameter!")
          @shards_table = config[:shards_table] or raise(ArgumentError, "Missing required :shards_table parameter!")

          # Local caches
          @shard_info_cache = {}
          @group_info_cache = {}

          @blocks_cache = Rails.cache
          @blocks_cache_prefix = config[:blocks_cache_prefix] || "#{@name}_block:"
        end

        #---------------------------------------------------------------------------------------------------------------
        def shard_for_key(key)
          block = block_for_key(key)

          # Auto-allocate new blocks
          block ||= allocate_new_block_for_key(key)
          raise ArgumentError, "Invalid key value, no shards found for this key and could not create a new block!" unless block

          # Load shard
          group_id = block['group_id'].to_i
          shard_info = shard_info_by_group_id(group_id)

          # Get config
          shard_connection_config(shard_info, group_id)
        end

        #---------------------------------------------------------------------------------------------------------------
        # Returns a block for a key
        def block_for_key(key, cache = true)
          # Cleanup the cache if asked to
          key_range = [ block_start_for_key(key), block_end_for_key(key) ]
          block_cache_key = "%d-%d" % key_range

          if cache
            cached_block = get_cached_block(block_cache_key)
            return cached_block if cached_block
          end

          # Fetch cached value or load from db
          block = begin
            sql = "SELECT * FROM #{map_table} WHERE start_id = #{key_range.first} AND end_id = #{key_range.last} LIMIT 1"
            connection.select_one(sql, 'Find a shard block')
          end

          set_cached_block(block_cache_key, block)

          return block
        end

        #---------------------------------------------------------------------------------------------------------------
        def get_cached_block(block_cache_key)
          @blocks_cache.read("#{@blocks_cache_prefix}#{block_cache_key}")
        end

        def set_cached_block(block_cache_key, block)
          @blocks_cache.write("#{@blocks_cache_prefix}#{block_cache_key}", block)
        end

        #---------------------------------------------------------------------------------------------------------------
        # Load group info
        def group_info_by_id(group_id, cache = true)
          # Cleanup the cache if asked to
          @group_info_cache[group_id] = nil unless cache

          # Either load from cache or from db
          @group_info_cache[group_id] ||= begin
            prepare_shard_models
            Group.find_by_id(group_id)
          end
        end

        # Load shard info
        def shard_info_by_id(shard_id, cache = true)
          # Cleanup the cache if asked to
          @shard_info_cache[shard_id] = nil unless cache

          # Either load from cache or from db
          @shard_info_cache[shard_id] ||= begin
            prepare_shard_models
            Shard.find_by_id(shard_id)
          end
        end

        # Load shard info using mapping info for a group
        def shard_info_by_group_id(group_id)
          # Load group
          group_info = group_info_by_id(group_id)
          raise ArgumentError, "Invalid group_id: #{group_id}" unless group_info

          shard_info = shard_info_by_id(group_info.shard_id)
          raise ArgumentError, "Invalid shard_id: #{group_info.shard_id}" unless shard_info

          return shard_info
        end

        #---------------------------------------------------------------------------------------------------------------
        def allocate_new_block_for_key(key)
          # Can't find any groups to use for blocks allocation!
          return nil unless group = least_loaded_group

          # Figure out block limits
          start_id = block_start_for_key(key)
          end_id = block_end_for_key(key)

          # Try to insert a new mapping (ignore duplicate key errors)
          sql = <<-SQL
            INSERT IGNORE INTO #{map_table}
                           SET start_id = #{start_id},
                               end_id = #{end_id},
                               group_id = #{group.id},
                               block_size = #{block_size},
                               created_at = NOW(),
                               updated_at = NOW()
          SQL
          connection.execute(sql, "Allocate new block")

          # Increment the blocks counter on the shard
          Group.update_counters(group.id, :blocks_count => +1)

          # Retry block search after creation
          block_for_key(key)
        end

        def least_loaded_group
          prepare_shard_models

          # Select group
          group = Group.first(:conditions => { :enabled => true, :open => true }, :order => 'blocks_count ASC')
          raise "Can't find any tablegroups to use for blocks allocation!" unless group
          return group
        end

        #---------------------------------------------------------------------------------------------------------------
        def block_start_for_key(key)
          block_size.to_i * (key.to_i / block_size.to_i)
        end

        def block_end_for_key(key)
          block_size.to_i + block_start_for_key(key)
        end

        #---------------------------------------------------------------------------------------------------------------
        # Create configuration (use mapping connection as a template)
        def shard_connection_config(shard, group_id)
          # Format connection name
          shard_name = "db_charmer_db_block_group_map_#{name}_s%d_g%d" % [ shard.id, group_id]

          # Here we get the mapping connection's configuration
          # They do not expose configs so we hack in and get the instance var
          # FIXME: Find a better way, maybe move config method to our ar extenstions
          connection.instance_variable_get(:@config).clone.merge(
            # Name for the connection factory
            :connection_name => shard_name,
            # Connection params
            :host => shard.db_host,
            :port => shard.db_port,
            :username => shard.db_user,
            :password => shard.db_pass,
            :database => group_database_name(shard, group_id)
          )
        end

        def group_database_name(shard, group_id)
          "%s_%05d" % [ shard.db_name_prefix, group_id ]
        end

        #---------------------------------------------------------------------------------------------------------------
        def create_shard(params)
          params = params.symbolize_keys
          [ :db_host, :db_port, :db_user, :db_pass, :db_name_prefix ].each do |arg|
            raise ArgumentError, "Missing required parameter: #{arg}" unless params[arg]
          end

          # Prepare model
          prepare_shard_models

          # Create the record
          Shard.create! do |shard|
            shard.db_host = params[:db_host]
            shard.db_port = params[:db_port]
            shard.db_user = params[:db_user]
            shard.db_pass = params[:db_pass]
            shard.db_name_prefix = params[:db_name_prefix]
          end
        end

        def shard_connections
          # Find all groups
          prepare_shard_models
          groups = Group.all(:conditions => { :enabled => true }, :include => :shard)
          # Map them to shards
          groups.map { |group| shard_connection_config(group.shard, group.id) }
        end

        # Prepare model for working with our shards table
        def prepare_shard_models
          Shard.set_table_name(shards_table)
          Shard.switch_connection_to(connection)

          Group.set_table_name(groups_table)
          Group.switch_connection_to(connection)
        end

      end
    end
  end
end

# This is a more sophisticated sharding method based on a database-backed
# blocks map that holds block-shard associations. It automatically
# creates new blocks for new keys and assigns them to shards.
#
module DbCharmer
  module Sharding
    module Method
      class DbBlockMap
        # Sharder name
        attr_accessor :name

        # Mapping db connection
        attr_accessor :connection, :connection_name

        # Mapping table name
        attr_accessor :map_table

        # Shards table name
        attr_accessor :shards_table

        # Sharding keys block size
        attr_accessor :block_size

        def initialize(config)
          @name = config[:name] or raise(ArgumentError, "Missing required :name parameter!")
          @connection = DbCharmer::ConnectionFactory.connect(config[:connection], true)
          @block_size = (config[:block_size] || 10000).to_i

          @map_table = config[:map_table] or raise(ArgumentError, "Missing required :map_table parameter!")
          @shards_table = config[:shards_table] or raise(ArgumentError, "Missing required :shards_table parameter!")

          # Local caches
          @shard_info_cache = {}

          @blocks_cache = Rails.cache
          @blocks_cache_prefix = config[:blocks_cache_prefix] || "#{@name}_block:"
        end

        def shard_for_key(key)
          block = block_for_key(key)

          begin
            # Auto-allocate new blocks
            block ||= allocate_new_block_for_key(key)
          rescue ActiveRecord::StatementInvalid => e
            raise unless e.message.include?('Duplicate entry')
            block = block_for_key(key)
          end

          raise ArgumentError, "Invalid key value, no shards found for this key and could not create a new block!" unless block

          # Bail if no shard found
          shard_id = block['shard_id'].to_i
          shard_info = shard_info_by_id(shard_id)
          raise ArgumentError, "Invalid shard_id: #{shard_id}" unless shard_info

          # Get config
          shard_connection_config(shard_info)
        end

        class ShardInfo < ActiveRecord::Base
          validates_presence_of :db_host
          validates_presence_of :db_port
          validates_presence_of :db_user
          validates_presence_of :db_pass
          validates_presence_of :db_name
        end

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

        def get_cached_block(block_cache_key)
          @blocks_cache.read("#{@blocks_cache_prefix}#{block_cache_key}")
        end

        def set_cached_block(block_cache_key, block)
          @blocks_cache.write("#{@blocks_cache_prefix}#{block_cache_key}", block)
        end

        # Load shard info
        def shard_info_by_id(shard_id, cache = true)
          # Cleanup the cache if asked to
          @shard_info_cache[shard_id] = nil unless cache

          # Either load from cache or from db
          @shard_info_cache[shard_id] ||= begin
            prepare_shard_model
            ShardInfo.find_by_id(shard_id)
          end
        end

        def allocate_new_block_for_key(key)
          # Can't find any shards to use for blocks allocation!
          return nil unless shard = least_loaded_shard

          # Figure out block limits
          start_id = block_start_for_key(key)
          end_id = block_end_for_key(key)

          # Try to insert a new mapping (ignore duplicate key errors)
          sql = <<-SQL
            INSERT INTO #{map_table}
                   SET start_id = #{start_id},
                       end_id = #{end_id},
                       shard_id = #{shard.id},
                       block_size = #{block_size},
                       created_at = NOW(),
                       updated_at = NOW()
          SQL
          connection.execute(sql, "Allocate new block")

          # Increment the blocks counter on the shard
          ShardInfo.update_counters(shard.id, :blocks_count => +1)

          # Retry block search after creation
          block_for_key(key)
        end

        def least_loaded_shard
          prepare_shard_model

          # Select shard
          shard = ShardInfo.all(:conditions => { :enabled => true, :open => true }, :order => 'blocks_count ASC', :limit => 1).first
          raise "Can't find any shards to use for blocks allocation!" unless shard
          return shard
        end

        def block_start_for_key(key)
          block_size.to_i * (key.to_i / block_size.to_i)
        end

        def block_end_for_key(key)
          block_size.to_i + block_start_for_key(key)
        end

        # Create configuration (use mapping connection as a template)
        def shard_connection_config(shard)
          # Format connection name
          shard_name = "db_charmer_db_block_map_#{name}_shard_%05d" % shard.id

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
            :database => shard.db_name
          )
        end

        def create_shard(params)
          params = params.symbolize_keys
          [ :db_host, :db_port, :db_user, :db_pass, :db_name ].each do |arg|
            raise ArgumentError, "Missing required parameter: #{arg}" unless params[arg]
          end

          # Prepare model
          prepare_shard_model

          # Create the record
          ShardInfo.create! do |shard|
            shard.db_host = params[:db_host]
            shard.db_port = params[:db_port]
            shard.db_user = params[:db_user]
            shard.db_pass = params[:db_pass]
            shard.db_name = params[:db_name]
          end
        end

        def shard_connections
          # Find all shards
          prepare_shard_model
          shards = ShardInfo.all(:conditions => { :enabled => true })
          # Map them to connections
          shards.map { |shard| shard_connection_config(shard) }
        end

        # Prepare model for working with our shards table
        def prepare_shard_model
          ShardInfo.set_table_name(shards_table)
          ShardInfo.switch_connection_to(connection)
        end

      end
    end
  end
end

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

        # Dictionary db connection
        attr_accessor :connection, :connection_name

        # Mapping table name
        attr_accessor :map_table

        # Shards table name
        attr_accessor :shards_table

        # Sharding keys block size
        attr_accessor :block_size

        def initialize(config)
          @name = config[:name] or raise(ArgumentError, "Missing required :name parameter!")
          @connection = DbCharmer::ConnectionFactory.connect(config[:connection])
          @block_size = (config[:block_size] || 10000).to_i

          @map_table = config[:map_table] or raise(ArgumentError, "Missing required :map_table parameter!")
          @shards_table = config[:shards_table] or raise(ArgumentError, "Missing required :shards_table parameter!")
        end

        def shard_for_key(key)
          block = block_for_key(key)

          # FIXME: Auto-allocate new blocks
          raise ArgumentError, "Invalid key value, no shards found for this key!" unless block

          # Bail if no shard found
          shard_id = block['shard_id'].to_i
          shard_info = shard_info_by_id(shard_id)
          raise ArgumentError, "Invalid shard_id: #{shard_id}" unless shard_info

          # Format connection config and return it
          shard_name = "db_charmer_db_block_dict_#{name}_shard_%05" % shard_id
          return shard_connection_config(shard_name, shard_info)
        end

      private

        def block_for_key(key)
          # FIXME: add caching
          sql = "SELECT * FROM #{dict_table} WHERE #{key} >= start_key AND #{key} < end_key LIMIT 1"
          connection.select_one(sql, 'Find a shard block')
        end

        # Load shard info
        def shard_info_by_id(shard_id)
          # FIXME: add caching
          sql = "SELECT * FROM #{shards_table} WHERE id = #{shard_id} LIMIT 1"
          connection.select_one(sql, 'Find a shard info')
        end

        # Create configuration (use dict connection as a template)
        def shard_connection_config(shard_name, shard_info)
          connection.config.clone.merge(
            # Name for the connection factory
            :name => shard_name,
            # Connection params
            :host => shard_info['db_host'],
            :port => shard_info['db_port'],
            :username => shard_info['db_user'],
            :password => shard_info['db_pass'],
            :database => shard_info['db_name']
          )
        end

      public

        class ShardInfo < ActiveRecord::Base
          validates_presence_of :db_host
          validates_presence_of :db_port
          validates_presence_of :db_user
          validates_presence_of :db_pass
          validates_presence_of :db_name
        end

        def create_shard(params)
          params = params.symbolize_keys
          [ :db_host, :db_port, :db_user, :db_pass, :db_name ].each do |arg|
            raise ArgumentError, "Missing required parameter: #{arg}" unless params[arg]
          end

          # Prepare model
          ShardInfo.set_table_name(shards_table)
          ShardInfo.switch_connection_to(connection)

          # Create the record
          ShardInfo.create! do |shard|
            shard.db_host = params[:db_host]
            shard.db_port = params[:db_port]
            shard.db_user = params[:db_user]
            shard.db_pass = params[:db_pass]
            shard.db_name = params[:db_name]
          end
        end

      end
    end
  end
end

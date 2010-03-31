module DbCharmer
  module MultiDbMigrations
    @multi_db_names = nil

    def migrate_with_db_wrapper(direction)
      @multi_db_names.each do |multi_db_name|
        on_db(multi_db_name) do
          migrate_without_db_wrapper(direction)
        end
      end
    end

    def on_db(db_name)
      name = db_name.is_a?(Hash) ? db_name[:name] : db_name.inspect
      announce "Switching connection to #{name}"
      # Switch connection
      old_proxy = ActiveRecord::Base.db_charmer_connection_proxy
      ActiveRecord::Base.switch_connection_to(db_name, DbCharmer.migration_connections_should_exist?)
      # Yield the block
      yield
    ensure
      # Switch it back
      announce "Checking all database connections"
      ActiveRecord::Base.verify_active_connections!
      announce "Switching connection back to default"
      ActiveRecord::Base.switch_connection_to(old_proxy)
    end

    def db_magic(opts = {})
      # Collect connections from all possible options
      conns = [ opts[:connection], opts[:connections] ]
      conns << shard_connections(opts[:sharded_connection]) if opts[:sharded_connection]

      # Get a unique set of connections
      conns = conns.flatten.compact.uniq
      raise ArgumentError, "No connection name - no magic!" unless conns.any?

      # Save connections
      @multi_db_names = conns
      class << self
        alias_method_chain :migrate, :db_wrapper
      end
    end

    # Return a list of connections to shards in a sharded connection
    def shard_connections(conn_name)
      conn = DbCharmer::Sharding.sharded_connection(conn_name)
      conn.shard_connections
    end
  end
end

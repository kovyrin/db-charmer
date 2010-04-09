module DbCharmer
  module MultiDbMigrations
    def self.extended(base)
      class << base
        alias_method_chain :migrate, :db_wrapper
      end
    end

    @@multi_db_names = {}
    def multi_db_names
      puts "Retrieving connections for #{self.name}"
      @@multi_db_names[self.name] || @@multi_db_names['ActiveRecord::Migration']
    end

    def multi_db_names=(names)
      puts "Setting connections for #{self.name}"
      @@multi_db_names[self.name] = names
    end

    def migrate_with_db_wrapper(direction)
      if names = multi_db_names
        names.each do |multi_db_name|
          on_db(multi_db_name) do
            migrate_without_db_wrapper(direction)
          end
        end
      else
        migrate_without_db_wrapper(direction)
      end
    end

    def on_db(db_name)
      name = db_name.is_a?(Hash) ? db_name[:name] : db_name.inspect
      announce "Switching connection to #{name}"
      # Switch connection
      old_proxy = ActiveRecord::Base.db_charmer_connection_proxy
      db_name = nil if db_name == :default
      ActiveRecord::Base.switch_connection_to(db_name, DbCharmer.connections_should_exist?)
      # Yield the block
      yield
    ensure
      # Switch it back
      ActiveRecord::Base.verify_active_connections!
      announce "Switching connection back"
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
      self.multi_db_names = conns
    end

    # Return a list of connections to shards in a sharded connection
    def shard_connections(conn_name)
      conn = DbCharmer::Sharding.sharded_connection(conn_name)
      conn.shard_connections
    end
  end
end

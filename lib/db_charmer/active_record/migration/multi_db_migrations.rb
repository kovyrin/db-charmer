module DbCharmer
  module ActiveRecord
    module Migration
      module MultiDbMigrations
        extend ActiveSupport::Concern

        included do
          if DbCharmer.rails32?
            alias_method_chain :migrate, :db_wrapper
          else
            class << self
              alias_method_chain :migrate, :db_wrapper
            end
          end
        end

        module ClassMethods
          @@multi_db_names = {}
          def multi_db_names
            @@multi_db_names[self.name] || @@multi_db_names['ActiveRecord::Migration']
          end

          def multi_db_names=(names)
            @@multi_db_names[self.name] = names
          end

          unless DbCharmer.rails32?
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
              name = db_name.is_a?(Hash) ? db_name[:connection_name] : db_name.inspect
              announce "Switching connection to #{name}"
              # Switch connection
              old_proxy = ::ActiveRecord::Base.db_charmer_connection_proxy
              db_name = nil if db_name == :default
              ::ActiveRecord::Base.switch_connection_to(db_name, DbCharmer.connections_should_exist?)
              # Yield the block
              yield
            ensure
              # Switch it back
              ::ActiveRecord::Base.verify_active_connections!
              announce "Switching connection back"
              ::ActiveRecord::Base.switch_connection_to(old_proxy)
            end
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

        def migrate_with_db_wrapper(direction)
          if names = self.class.multi_db_names
            names.each do |multi_db_name|
              on_db(multi_db_name) do
                migrate_without_db_wrapper(direction)
              end
            end
          else
            migrate_without_db_wrapper(direction)
          end
        end

        def record_on_db(db_name, block)
          recorder = ::ActiveRecord::Migration::CommandRecorder.new(DbCharmer::ConnectionFactory.connect(db_name))
          old_recorder, @connection = @connection, recorder
          block.call
          old_recorder.record :on_db, [db_name, @connection]
          @connection = old_recorder
        end

        def replay_commands_on_db(name, commands)
          on_db(name) do
            commands.each do |cmd, args|
              send(cmd, *args)
            end
          end
        end

        def on_db(db_name, &block)
          if @connection.is_a?(::ActiveRecord::Migration::CommandRecorder)
            record_on_db(db_name, block)
            return
          end

          name = db_name.is_a?(Hash) ? db_name[:connection_name] : db_name.inspect
          announce "Switching connection to #{name}"
          # Switch connection
          old_connection, old_proxy = @connection, ::ActiveRecord::Base.db_charmer_connection_proxy
          db_name = nil if db_name == :default
          ::ActiveRecord::Base.switch_connection_to(db_name, DbCharmer.connections_should_exist?)
          # Yield the block
          ::ActiveRecord::Base.connection_pool.with_connection do |conn|
            @connection = conn
            yield
          end
        ensure
          @connection = old_connection
          # Switch it back
          ::ActiveRecord::Base.verify_active_connections!
          announce "Switching connection back"
          ::ActiveRecord::Base.switch_connection_to(old_proxy)
        end
      end
    end
  end
end

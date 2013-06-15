module DbCharmer
  module ActiveRecord
    module Migration
      module MultiDbMigrations

        def self.append_features(base)
          return false if base < self
          super
          base.extend const_get("ClassMethods") if const_defined?("ClassMethods")

          base.class_eval do
            if DbCharmer.rails31?
              alias_method_chain :migrate, :db_wrapper
            else
              class << self
                alias_method_chain :migrate, :db_wrapper
              end
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

          unless DbCharmer.rails31?
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

        #-------------------------------------------------------------------------------------------
        def record_on_db(db_name, block)
          # Switch current recorder to a new one with specified connection
          old_recorder = @connection
          new_connection = DbCharmer::ConnectionFactory.connect(db_name)
          @connection = ::ActiveRecord::Migration::CommandRecorder.new(new_connection)
          @connection.reverting = old_recorder.reverting if DbCharmer.rails4?

          # Call the block to record commands in the block
          block.call

          # Record on_db call and pass new recorder with it
          old_recorder.record :on_db, [ db_name, @connection ]

          # Switch recorder back
          @connection = old_recorder
        end

        def replay_commands_on_db(name, recorder)
          on_db(name) do
            commands = (DbCharmer.rails4?) ? recorder.commands : recorder.inverse
            commands.each do |cmd, args|
              send(cmd, args)
            end
          end
        end

        #-------------------------------------------------------------------------------------------
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
          announce "Switching connection back"
          ::ActiveRecord::Base.switch_connection_to(old_proxy)
        end
      end
    end
  end
end

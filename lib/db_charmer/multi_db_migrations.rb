module DbCharmer
  module MultiDbMigrations
    class MigrationAbstractClass < ActiveRecord::Base
      abstract_class = true
      hijack_connection!
    end

    module ClassMethods
      def hijack_connection!
        class << self
          def connection
#            puts "DEBUG: Retrieving migration connection"
            MigrationAbstractClass.connection
          end
        end
      end

      def on_db(db_name)
        hijack_connection!
        announce "Switching connection to #{db_name}"
        old_proxy = MigrationAbstractClass.db_charmer_connection_proxy
        MigrationAbstractClass.switch_connection_to(db_name, DbCharmer.migration_connections_should_exist?)
        yield
      ensure
        announce "Checking all database connections"
        ActiveRecord::Base.verify_active_connections!
        announce "Switching connection back to default"
        MigrationAbstractClass.switch_connection_to(old_proxy)
      end

      def works_on_db(db_name)
        hijack_connection!
        MigrationAbstractClass.switch_connection_to(db_name, DbCharmer.migration_connections_should_exist?)
      end

      def db_magic(opts = {})
        raise ArgumentError, "No connection name - no magic!" unless opts[:connection]
        works_on_db(opts[:connection])
      end
    end
  end
end

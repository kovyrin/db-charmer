# Multiple-database migrations feature for Rails
# ==============================================
#
# This module adds +works_on_db+ method to the Rails migration classes
# and allows us to specify database connection name used for migrations to run.
#
# With this method we're going to carefully split the main database to a set of 
# smaller and more specialized databases that will have their own backup 
# schedules and replication factors.
#
# Migration class example (global connection rewrite):
#
#   class MultiDbTest < ActiveRecord::Migration
#     works_on_db :second_db
#   
#     def self.up
#       create_table :test_table, :force => true do |t|
#         t.string :test_string
#         t.timestamps
#       end
#     end
#   
#     def self.down
#       drop_table :test_table
#     end
#   end
#
# Migration class example (block-level connection rewrite):
#
#   class MultiDbTest < ActiveRecord::Migration
#   
#     def self.up
#       on_db :second_db do
#         create_table :test_table, :force => true do |t|
#           t.string :test_string
#           t.timestamps
#         end
#       end
#     end
#   
#     def self.down
#       on_db :second_db { drop_table :test_table }
#     end
#   end
#
#
# In development and test environments we could skip this +:second_db+ connection 
# from our database.yml files, but in production we'd specify it and get the table 
# created on a separate server and/or in a separate database.
#

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
            puts "DEBUG: Retrieving migration connection"
            MigrationAbstractClass.connection
          end          
        end
      end
      
      def migrate_with_db_wrapper(direction)
        on_db(@@multi_db_name) { migrate_without_db_wrapper(direction) }
      end
    
      def on_db(db_name, require_config_to_exist = true)
        hijack_connection!
        announce "Switching connection to #{db_name}"
        old_proxy = MigrationAbstractClass.db_charmer_connection_proxy
        MigrationAbstractClass.switch_connection_to(db_name, require_config_to_exist)
        yield
      ensure
        announce "Checking all database connections"
        ActiveRecord::Base.verify_active_connections!
        announce "Switching connection back to default"
        MigrationAbstractClass.switch_connection_to(old_proxy)
      end
    
      def works_on_db(db_name, require_config_to_exist = true)
        hijack_connection!
        MigrationAbstractClass.switch_connection_to(db_name, require_config_to_exist)
      end
    end
  end
end

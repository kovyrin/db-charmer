#puts "Loading DbCharmer..."

module DbCharmer
  @@migration_connections_should_exist = Rails.env.production?
  mattr_accessor :migration_connections_should_exist

  def self.migration_connections_should_exist?
    !! migration_connections_should_exist
  end

  @@connections_should_exist = Rails.env.production?
  mattr_accessor :connections_should_exist

  def self.connections_should_exist?
    !! connections_should_exist
  end

  def self.logger
    return Rails.logger if defined?(Rails)
    @logger ||= Logger.new(STDERR)
  end
end

class Object
  def self.proxy?
    false
  end

  def proxy?
    false
  end
end

#puts "Extending AR..."

require 'db_charmer/active_record_extensions'
require 'db_charmer/connection_factory'
require 'db_charmer/connection_proxy'
require 'db_charmer/connection_switch'
require 'db_charmer/scope_proxy'
require 'db_charmer/multi_db_proxy'

# Enable misc AR extensions
ActiveRecord::Base.extend(DbCharmer::ActiveRecordExtensions::ClassMethods)

# Enable connections switching in AR
ActiveRecord::Base.extend(DbCharmer::ConnectionSwitch::ClassMethods)

# Enable connection proxy in AR
ActiveRecord::Base.extend(DbCharmer::MultiDbProxy::ClassMethods)
ActiveRecord::Base.extend(DbCharmer::MultiDbProxy::MasterSlaveClassMethods)
ActiveRecord::Base.send(:include, DbCharmer::MultiDbProxy::InstanceMethods)

# Enable connection proxy for scopes
ActiveRecord::NamedScope::Scope.send(:include, DbCharmer::ScopeProxy::InstanceMethods)

# Enable connection proxy for associations
# WARNING: Inject methods to association class right here (they proxy include calls somewhere else, so include does not work)
module ActiveRecord
  module Associations
    class AssociationProxy
      def proxy?
        true
      end

      def on_db(con, proxy_target = nil, &block)
        proxy_target ||= self
        @reflection.klass.on_db(con, proxy_target, &block)
      end

      def on_slave(con = nil, &block)
        @reflection.klass.on_slave(con, self, &block)
      end

      def on_master(&block)
        @reflection.klass.on_master(self, &block)
      end
    end
  end
end

#puts "Doing the magic..."

require 'db_charmer/db_magic'
require 'db_charmer/finder_overrides'
require 'db_charmer/multi_db_migrations'
require 'db_charmer/multi_db_proxy'

# Enable multi-db migrations
ActiveRecord::Migration.extend(DbCharmer::MultiDbMigrations)

# Enable the magic
ActiveRecord::Base.extend(DbCharmer::DbMagic::ClassMethods)

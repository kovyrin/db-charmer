module DbCharmer
  @@connections_should_exist = Rails.env.production?
  mattr_accessor :connections_should_exist

  def self.connections_should_exist?
    !! connections_should_exist
  end

  def self.logger
    return Rails.logger if defined?(Rails)
    @logger ||= Logger.new(STDERR)
  end

  def self.with_remapped_databases(mappings, &proc)
    old_mappings = ActiveRecord::Base.db_charmer_database_remappings
    begin
      ActiveRecord::Base.db_charmer_database_remappings = mappings
      if mappings[:master] || mappings['master']
        with_all_hijacked(&proc)
      else
        proc.call
      end
    ensure
      ActiveRecord::Base.db_charmer_database_remappings = old_mappings
    end
  end

  def self.hijack_new_classes?
    @@hijack_new_classes
  end

private

  @@hijack_new_classes = false
  def self.with_all_hijacked
    old_hijack_new_classes = @@hijack_new_classes
    begin
      @@hijack_new_classes = true
      ActiveRecord::Base.send(:subclasses).each do |subclass|
        subclass.hijack_connection!
      end
      yield
    ensure
      @@hijack_new_classes = old_hijack_new_classes
    end
  end
end

# These methods are added to all objects so we could call proxy? on anything
# and figure if an object is a proxy w/o hitting method_missing or respond_to?
class Object
  def self.proxy?
    false
  end

  def proxy?
    false
  end
end

# We need blankslate for all the proxies we have
require 'blankslate'

require 'db_charmer/active_record_extensions'
require 'db_charmer/abstract_adapter_extensions'

require 'db_charmer/connection_factory'
require 'db_charmer/connection_proxy'
require 'db_charmer/connection_switch'
require 'db_charmer/scope_proxy'
require 'db_charmer/multi_db_proxy'

# Enable misc AR extensions
ActiveRecord::Base.extend(DbCharmer::ActiveRecordExtensions::ClassMethods)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, DbCharmer::AbstractAdapterExtensions::InstanceMethods)

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

require 'db_charmer/db_magic'
require 'db_charmer/finder_overrides'
require 'db_charmer/association_preload'
require 'db_charmer/multi_db_migrations'
require 'db_charmer/multi_db_proxy'

# Enable multi-db migrations
ActiveRecord::Migration.extend(DbCharmer::MultiDbMigrations)

# Enable the magic
ActiveRecord::Base.extend(DbCharmer::DbMagic::ClassMethods)

# Setup association preload magic
ActiveRecord::Base.extend(DbCharmer::AssociationPreload::ClassMethods)

class ActiveRecord::Base
  class << self
    def inherited_with_hijacking(subclass)
      out = inherited_without_hijacking(subclass)
      hijack_connection! if DbCharmer.hijack_new_classes?
      out
    end

    alias_method_chain :inherited, :hijacking
  end
end

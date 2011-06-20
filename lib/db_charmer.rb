module DbCharmer
  # Accessors
  @@connections_should_exist = true
  mattr_accessor :connections_should_exist

  # Try to detect current environment or use development by default
  if defined?(Rails)
    @@env = Rails.env
  elsif ENV['RAILS_ENV']
    @@env = ENV['RAILS_ENV']
  elsif ENV['RACK_ENV']
    @@env = ENV['RACK_ENV']
  else
    @@env = 'development'
  end
  mattr_accessor :env

  def self.connections_should_exist?
    !! connections_should_exist
  end

  def self.logger
    return Rails.logger if defined?(Rails)
    @logger ||= Logger.new(STDERR)
  end

  def self.with_remapped_databases(mappings, &proc)
    old_mappings = ::ActiveRecord::Base.db_charmer_database_remappings
    begin
      ::ActiveRecord::Base.db_charmer_database_remappings = mappings
      if mappings[:master] || mappings['master']
        with_all_hijacked(&proc)
      else
        proc.call
      end
    ensure
      ::ActiveRecord::Base.db_charmer_database_remappings = old_mappings
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
      ::ActiveRecord::Base.send(:subclasses).each do |subclass|
        subclass.hijack_connection!
      end
      yield
    ensure
      @@hijack_new_classes = old_hijack_new_classes
    end
  end
end

# Add useful methods to global object
require 'db_charmer/core_extensions'

require 'db_charmer/connection_factory'
require 'db_charmer/connection_proxy'
require 'db_charmer/force_slave_reads'

# Add our custom class-level attributes to AR models
require 'db_charmer/active_record/class_attributes'
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::ClassAttributes)

# Enable connections switching in AR
require 'db_charmer/active_record/connection_switching'
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::ConnectionSwitching)

# Enable misc AR extensions
require 'db_charmer/abstract_adapter/log_formatting'
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, DbCharmer::AbstractAdapter::LogFormatting)

# Enable connection proxy in AR
require 'db_charmer/active_record/multi_db_proxy'
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::MultiDbProxy::ClassMethods)
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::MultiDbProxy::MasterSlaveClassMethods)
ActiveRecord::Base.send(:include, DbCharmer::ActiveRecord::MultiDbProxy::InstanceMethods)

# Enable connection proxy for scopes
require 'db_charmer/active_record/named_scope/scope_proxy'
ActiveRecord::NamedScope::Scope.send(:include, DbCharmer::ActiveRecord::NamedScope::ScopeProxy)

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

# Enable multi-db migrations
require 'db_charmer/active_record/migration/multi_db_migrations'
ActiveRecord::Migration.extend(DbCharmer::ActiveRecord::Migration::MultiDbMigrations)

# Enable the magic
require 'db_charmer/active_record/finder_overrides'
require 'db_charmer/active_record/sharding'
require 'db_charmer/active_record/db_magic'
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::DbMagic)

# Setup association preload magic
require 'db_charmer/active_record/association_preload'
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::AssociationPreload)

# Open up really useful API method
ActiveRecord::AssociationPreload::ClassMethods.send(:public, :preload_associations)

class ::ActiveRecord::Base
  class << self
    def inherited_with_hijacking(subclass)
      out = inherited_without_hijacking(subclass)
      hijack_connection! if DbCharmer.hijack_new_classes?
      out
    end

    alias_method_chain :inherited, :hijacking
  end
end

#-----------------------------------------------------------------------------------------------------------------------
# Extend ActionController to support forcing slave reads
require 'db_charmer/action_controller/force_slave_reads'
ActionController::Base.extend(DbCharmer::ActionController::ForceSlaveReads::ClassMethods)
ActionController::Base.send(:include, DbCharmer::ActionController::ForceSlaveReads::InstanceMethods)

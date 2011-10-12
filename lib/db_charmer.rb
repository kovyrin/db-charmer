# In Rails 2.2 they did not add it to the autoload so it won't work w/o this require
require 'active_record/version' unless defined?(::ActiveRecord::VERSION::MAJOR)

module DbCharmer
  # Configure autoload
  autoload :Sharding, 'db_charmer/sharding'
  autoload :Version,  'db_charmer/version'
  module ActionController
    autoload :ForceSlaveReads, 'db_charmer/action_controller/force_slave_reads'
  end

  # Used in all Rails3-specific places
  def self.rails3?
    ::ActiveRecord::VERSION::MAJOR > 2
  end

  # Used in all Rails2-specific places
  def self.rails2?
    ::ActiveRecord::VERSION::MAJOR == 2
  end

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

  # Extend ActionController to support forcing slave reads
  def self.enable_controller_magic!
    ::ActionController::Base.extend(DbCharmer::ActionController::ForceSlaveReads::ClassMethods)
    ::ActionController::Base.send(:include, DbCharmer::ActionController::ForceSlaveReads::InstanceMethods)
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
      subclasses_method = DbCharmer.rails3? ? :descendants : :subclasses
      ::ActiveRecord::Base.send(subclasses_method).each do |subclass|
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

# Enable AR logging extensions
if DbCharmer.rails3?
  require 'db_charmer/rails3/abstract_adapter/connection_name'
  require 'db_charmer/rails3/active_record/log_subscriber'
  ActiveRecord::LogSubscriber.send(:include, DbCharmer::ActiveRecord::LogSubscriber)
  ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, DbCharmer::AbstractAdapter::ConnectionName)
else
  require 'db_charmer/rails2/abstract_adapter/log_formatting'
  ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, DbCharmer::AbstractAdapter::LogFormatting)
end

# Enable connection proxy in AR
require 'db_charmer/active_record/multi_db_proxy'
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::MultiDbProxy::ClassMethods)
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::MultiDbProxy::MasterSlaveClassMethods)
ActiveRecord::Base.send(:include, DbCharmer::ActiveRecord::MultiDbProxy::InstanceMethods)

# Enable connection proxy for relations
if DbCharmer.rails3?
  require 'db_charmer/rails3/active_record/relation_method'
  require 'db_charmer/rails3/active_record/relation/connection_routing'
  ActiveRecord::Base.extend(DbCharmer::ActiveRecord::RelationMethod)
  ActiveRecord::Relation.send(:include, DbCharmer::ActiveRecord::Relation::ConnectionRouting)
end

# Enable connection proxy for scopes (rails 2.x only)
if DbCharmer.rails2?
  require 'db_charmer/rails2/active_record/named_scope/scope_proxy'
  ActiveRecord::NamedScope::Scope.send(:include, DbCharmer::ActiveRecord::NamedScope::ScopeProxy)
end

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
if DbCharmer.rails3?
  require 'db_charmer/rails3/active_record/master_slave_routing'
else
  require 'db_charmer/rails2/active_record/master_slave_routing'
end

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

# Add gem tasks to Rails app
if DbCharmer.rails3?
  require 'db_charmer/railtie.rb'
end

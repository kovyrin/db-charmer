# In Rails 2.2 they did not add it to the autoload so it won't work w/o this require
require 'active_record/version' unless defined?(::ActiveRecord::VERSION::MAJOR)
require 'active_support/core_ext'

if defined?(Rails)
  require "db_charmer/railtie"
end

#---------------------------------------------------------------------------------------------------
module DbCharmer
  # Configure autoload
  autoload :Sharding, 'db_charmer/sharding'
  autoload :Version,  'db_charmer/version'
  module ActionController
    autoload :ForceSlaveReads, 'db_charmer/action_controller/force_slave_reads'
  end

  #-------------------------------------------------------------------------------------------------
  # Used in all Rails3-specific places
  def self.rails3?
    ::ActiveRecord::VERSION::MAJOR > 2
  end

  # Used in all Rails3.1-specific places
  def self.rails31?
    rails3? && ::ActiveRecord::VERSION::MINOR >= 1
  end

  # Used in all Rails2-specific places
  def self.rails2?
    ::ActiveRecord::VERSION::MAJOR == 2
  end

  # Detect broken Rails version
  def self.rails324?
    ActiveRecord::VERSION::STRING == '3.2.4'
  end

  #-------------------------------------------------------------------------------------------------
  # Returns true if we're running within a Rails project
  def self.running_with_rails?
    defined?(Rails) && Rails.respond_to?(:env)
  end

  # Returns current environment name based on Rails or Rack environment variables
  def self.detect_environment
    return Rails.env if running_with_rails?
    ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'default'
  end

  # Try to detect current environment or use development by default
  @@env = DbCharmer.detect_environment
  mattr_accessor :env

  #-------------------------------------------------------------------------------------------------
  # Accessors
  @@connections_should_exist = true
  mattr_accessor :connections_should_exist

  def self.connections_should_exist?
    !! connections_should_exist
  end

  #-------------------------------------------------------------------------------------------------
  def self.logger
    return Rails.logger if running_with_rails?
    @@logger ||= Logger.new(STDERR)
  end

  #-------------------------------------------------------------------------------------------------
  # Extend ActionController to support forcing slave reads
  def self.enable_controller_magic!
    ::ActionController::Base.extend(DbCharmer::ActionController::ForceSlaveReads::ClassMethods)
    ::ActionController::Base.send(:include, DbCharmer::ActionController::ForceSlaveReads::InstanceMethods)
  end
end

#---------------------------------------------------------------------------------------------------
# Print warning about the broken Rails 2.3.4
puts "WARNING: Rails 3.2.4 is not officially supported by DbCharmer. Please upgrade." if DbCharmer.rails324?

#---------------------------------------------------------------------------------------------------
# Add useful methods to global object
require 'db_charmer/core_extensions'

require 'db_charmer/connection_factory'
require 'db_charmer/connection_proxy'
require 'db_charmer/force_slave_reads'
require 'db_charmer/with_remapped_databases'

#---------------------------------------------------------------------------------------------------
# Add our custom class-level attributes to AR models
require 'db_charmer/active_record/class_attributes'
require 'active_record'
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::ClassAttributes)

#---------------------------------------------------------------------------------------------------
# Enable connections switching in AR
require 'db_charmer/active_record/connection_switching'
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::ConnectionSwitching)

#---------------------------------------------------------------------------------------------------
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

#---------------------------------------------------------------------------------------------------
# Enable connection proxy in AR
require 'db_charmer/active_record/multi_db_proxy'
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::MultiDbProxy::ClassMethods)
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::MultiDbProxy::MasterSlaveClassMethods)
ActiveRecord::Base.send(:include, DbCharmer::ActiveRecord::MultiDbProxy::InstanceMethods)

#---------------------------------------------------------------------------------------------------
# Enable connection proxy for relations
if DbCharmer.rails3?
  require 'db_charmer/rails3/active_record/relation_method'
  require 'db_charmer/rails3/active_record/relation/connection_routing'
  ActiveRecord::Base.extend(DbCharmer::ActiveRecord::RelationMethod)
  ActiveRecord::Relation.send(:include, DbCharmer::ActiveRecord::Relation::ConnectionRouting)
end

#---------------------------------------------------------------------------------------------------
# Enable connection proxy for scopes (rails 2.x only)
if DbCharmer.rails2?
  require 'db_charmer/rails2/active_record/named_scope/scope_proxy'
  ActiveRecord::NamedScope::Scope.send(:include, DbCharmer::ActiveRecord::NamedScope::ScopeProxy)
end

#---------------------------------------------------------------------------------------------------
# Enable connection proxy for associations
# WARNING: Inject methods to association class right here because they proxy +include+ calls
#          somewhere else, which means we could not use +include+ method here
association_proxy_class = DbCharmer.rails31? ? ActiveRecord::Associations::CollectionProxy :
                                               ActiveRecord::Associations::AssociationProxy
association_proxy_class.class_eval do
  def proxy?
    true
  end

  if DbCharmer.rails31?
    def on_db(con, proxy_target = nil, &block)
      proxy_target ||= self
      @association.klass.on_db(con, proxy_target, &block)
    end

    def on_slave(con = nil, &block)
      @association.klass.on_slave(con, self, &block)
    end

    def on_master(&block)
      @association.klass.on_master(self, &block)
    end
  else
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

#---------------------------------------------------------------------------------------------------
# Enable multi-db migrations
require 'db_charmer/active_record/migration/multi_db_migrations'
ActiveRecord::Migration.send(:include, DbCharmer::ActiveRecord::Migration::MultiDbMigrations)

if DbCharmer.rails31?
  require 'db_charmer/rails31/active_record/migration/command_recorder'
  ActiveRecord::Migration::CommandRecorder.send(:include, DbCharmer::ActiveRecord::Migration::CommandRecorder)
end

#---------------------------------------------------------------------------------------------------
# Enable the magic
if DbCharmer.rails3?
  require 'db_charmer/rails3/active_record/master_slave_routing'
else
  require 'db_charmer/rails2/active_record/master_slave_routing'
end

require 'db_charmer/active_record/sharding'
require 'db_charmer/active_record/db_magic'
ActiveRecord::Base.extend(DbCharmer::ActiveRecord::DbMagic)

#---------------------------------------------------------------------------------------------------
# Setup association preload magic
if DbCharmer.rails31?
  require 'db_charmer/rails31/active_record/preloader/association'
  ActiveRecord::Associations::Preloader::Association.send(:include, DbCharmer::ActiveRecord::Preloader::Association)
  require 'db_charmer/rails31/active_record/preloader/has_and_belongs_to_many'
  ActiveRecord::Associations::Preloader::HasAndBelongsToMany.send(:include, DbCharmer::ActiveRecord::Preloader::HasAndBelongsToMany)
else
  require 'db_charmer/active_record/association_preload'
  ActiveRecord::Base.extend(DbCharmer::ActiveRecord::AssociationPreload)

  # Open up really useful API method
  ActiveRecord::AssociationPreload::ClassMethods.send(:public, :preload_associations)
end

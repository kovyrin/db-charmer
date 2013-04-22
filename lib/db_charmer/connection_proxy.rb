# Simple proxy that sends all method calls to a real database connection
module DbCharmer
  class ConnectionProxy < ActiveSupport::BasicObject
    # We need to do this because in Rails 2.3 BasicObject does not remove object_id method, which is stupid
    undef_method(:object_id) if instance_methods.member?('object_id')

    # We use this to get a connection class from the proxy
    attr_accessor :abstract_connection_class

    def initialize(abstract_class, db_name)
      @abstract_connection_class = abstract_class
      @db_name = db_name
    end

    def db_charmer_connection
      @abstract_connection_class.retrieve_connection
    end

    def db_charmer_connection_name
      @db_name
    end

    def db_charmer_connection_proxy
      self
    end

    def nil?
      false
    end

    RESPOND_TO_METHODS = [:abstract_connection_class, :db_charmer_connection_name, :db_charmer_connection_proxy, :db_charmer_connection, :nil?].freeze
    def respond_to?(method)
      RESPOND_TO_METHODS.include?(method) ? true : db_charmer_connection.send(:respond_to?, method)
    end

    def method_missing(meth, *args, &block)
      db_charmer_connection.send(meth, *args, &block)
    end
  end
end

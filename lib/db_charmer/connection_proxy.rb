# Simple proxy that sends all method calls to a real database connection
module DbCharmer
  class ConnectionProxy < DbCharmer::EmptyObject
    # We use this to get a connection class from the proxy
    attr_accessor :abstract_connection_class

    def initialize(abstract_class, db_name)
      @abstract_connection_class = abstract_class
      @db_name = db_name
    end

    def db_charmer_connection_name
      @db_name
    end

    def db_charmer_connection_proxy
      self
    end

    def method_missing(meth, *args, &block)
      @abstract_connection_class.retrieve_connection.send(meth, *args, &block)
    end
  end
end

# Simple proxy that sends all method calls to a real database connection
module DbCharmer
  class ConnectionProxy < BlankSlate
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

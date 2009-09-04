module DbCharmer
  class ConnectionProxy < BlankSlate
    def initialize(abstract_class)
      @abstract_connection_class = abstract_class
    end

    def method_missing(meth, *args, &block)
      @abstract_connection_class.retrieve_connection.send(meth, *args, &block)
    end
  end
end

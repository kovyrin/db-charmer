module DbCharmer
  class ConnectionProxy < BlankSlate
    @@abstract_connection_class = nil

    def initialize(abstract_class)
      @@abstract_connection_class = abstract_class
    end
    
    def method_missing(meth, *args)
      puts "DEBUG: proxying #{meth} call to #{@@abstract_connection_class}"
      @@abstract_connection_class.retrieve_connection.send(meth, *args)
    end
  end
end

# This is a simple proxy class used as a default connection on sharded models
#
# The idea is to proxy all utility method calls to a real connection (set by
# the +set_real_connection+ method when we switch shards) and fail on real
# database querying calls forcing users to switch shard connections.
#
module DbCharmer
  class StubConnection
    def initialize(real_conn = nil)
      @real_conn = real_conn
    end

    def set_real_connection(real_conn)
      @real_conn = real_conn
    end

    def method_missing(meth, *args, &block)
      # Fail on database statements
      if ActiveRecord::ConnectionAdapters::DatabaseStatements.instance_methods.member?(meth.to_s)
        raise ActiveRecord::ConnectionNotEstablished, "You have to switch connection on your model before using it!"
      end

      # Fail if no connection has been established yet
      unless @real_conn
        raise  ActiveRecord::ConnectionNotEstablished, "No real connection to proxy this method to!"
      end

      # Proxy the call to our real connection target
      @real_conn.__send__(meth, *args, &block)
    end
  end
end

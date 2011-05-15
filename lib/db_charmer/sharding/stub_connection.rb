# This is a simple proxy class used as a default connection on sharded models
#
# The idea is to proxy all utility method calls to a real connection (set by
# the +set_real_connection+ method when we switch shards) and fail on real
# database querying calls forcing users to switch shard connections.
#
module DbCharmer
  module Sharding
    class StubConnection
      attr_accessor :sharded_connection

      def initialize(sharded_connection)
        @sharded_connection = sharded_connection
        @real_conn = nil
      end

      def set_real_connection(real_conn)
        @real_conn = real_conn
      end

      def real_connection
        # Return memoized real connection
        return @real_conn if @real_conn

        # If sharded connection supports shards enumeration, get the first shard
        conn = sharded_connection.shard_connections.try(:first)

        # If we do not have real connection yet, try to use the default one (if it is supported by the sharder)
        conn ||= sharded_connection.sharder.shard_for_key(:default) if sharded_connection.support_default_shard?

        # Get connection proxy for our real connection
        return nil unless conn
        @real_conn = ::ActiveRecord::Base.coerce_to_connection_proxy(conn, DbCharmer.connections_should_exist?)
      end

      def method_missing(meth, *args, &block)
        # Fail on database statements
        if ::ActiveRecord::ConnectionAdapters::DatabaseStatements.instance_methods.member?(meth.to_s)
          raise ::ActiveRecord::ConnectionNotEstablished, "You have to switch connection on your model before using it!"
        end

        # Fail if no connection has been established yet
        unless real_connection
          raise ::ActiveRecord::ConnectionNotEstablished, "No real connection to proxy this method to!"
        end

        # Proxy the call to our real connection target
        real_connection.__send__(meth, *args, &block)
      end
    end
  end
end

module DbCharmer
  module ConnectionSwitch
    module ClassMethods
      def coerce_to_connection_proxy(conn, should_exist = true)
        return nil if conn.nil?

        if conn.kind_of?(Symbol) || conn.kind_of?(String)
          return DbCharmer::ConnectionFactory.connect(conn, should_exist)
        end

        if conn.kind_of?(Hash)
          conn = conn.symbolize_keys
          raise ArgumentError, "Missing required :connection_name parameter" unless conn[:connection_name]
          return DbCharmer::ConnectionFactory.connect_to_db(conn[:connection_name], conn)
        end

        if conn.respond_to?(:db_charmer_connection_proxy)
          return conn.db_charmer_connection_proxy
        end

        if conn.kind_of?(ActiveRecord::ConnectionAdapters::AbstractAdapter) || conn.kind_of?(DbCharmer::Sharding::StubConnection)
          return conn
        end

        raise "Unsupported connection type: #{conn.class}"
      end

      def switch_connection_to(conn, require_config_to_exist = true)
        new_conn = coerce_to_connection_proxy(conn, require_config_to_exist)

        if db_charmer_connection_proxy.is_a?(DbCharmer::Sharding::StubConnection)
          db_charmer_connection_proxy.set_real_connection(new_conn)
        end

        self.db_charmer_connection_proxy = new_conn
        self.hijack_connection!
      end
    end
  end
end

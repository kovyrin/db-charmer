module DbCharmer
  module ConnectionSwitch
    module ClassMethods
      def switch_connection_to(conn, require_config_to_exist = true)
        puts "Assigning connection proxy for #{self}"
        self.connection_proxy = case conn
          when NilClass then
            conn
          when Symbol, String then
            DbCharmer::ConnectionFactory.connect(conn, require_config_to_exist)
          else
            if conn.respond_to?(:connection_proxy)
              conn.connection_proxy
            else
              raise "Unsupported connection type: #{conn.class}"
            end
        end
      end
    end
  end
end

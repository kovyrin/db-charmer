module DbCharmer
  module ConnectionSwitch
    module ClassMethods
      def coerce_to_connection_proxy(conn, should_exist = true)
        return nil if conn.nil?

        if conn.kind_of?(Symbol) || conn.kind_of?(String)
          return DbCharmer::ConnectionFactory.connect(conn, should_exist)
        end
            
        if conn.respond_to?(:db_charmer_connection_proxy)
          return conn.db_charmer_connection_proxy
        end
        
        if conn.kind_of?(ActiveRecord::ConnectionAdapters::AbstractAdapter)
          return conn
        end
        
        raise "Unsupported connection type: #{conn.class}"
      end
      
      def switch_connection_to(conn, require_config_to_exist = true)
        puts "DEBUG: Assigning connection proxy for #{self}"
        self.db_charmer_connection_proxy = coerce_to_connection_proxy(conn, require_config_to_exist)
        self.hijack_connection!
      end
    end
  end
end

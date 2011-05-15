module DbCharmer
  module ActiveRecord
    module ConnectionSwitching
      def establish_real_connection_if_exists(name, should_exist = false)
        name = name.to_s

        # Check environment name
        config = configurations[DbCharmer.env]
        unless config
          error = "Invalid environment name (does not exist in database.yml): #{DbCharmer.env}. Please set correct Rails.env or DbCharmer.env."
          raise ArgumentError, error
        end

        # Check connection name
        config = config[name]
        unless config
          if should_exist
            raise ArgumentError, "Invalid connection name (does not exist in database.yml): #{DbCharmer.env}/#{name}"
          end
          return # No need to establish connection - they do not want us to
        end

        # Pass connection name with config
        config[:connection_name] = name
        establish_connection(config)
      end

      #-----------------------------------------------------------------------------------------------------------------
      def hijack_connection!
        return if self.respond_to?(:connection_with_magic)
        class << self
          def connection_with_magic
            db_charmer_remapped_connection || db_charmer_connection_proxy || connection_without_magic
          end
          alias_method_chain :connection, :magic
        end
      end

      #-----------------------------------------------------------------------------------------------------------------
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

        if conn.kind_of?(::ActiveRecord::ConnectionAdapters::AbstractAdapter) || conn.kind_of?(DbCharmer::Sharding::StubConnection)
          return conn
        end

        raise "Unsupported connection type: #{conn.class}"
      end

      #-----------------------------------------------------------------------------------------------------------------
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

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
          # Make sure we check our accessors before going to the default connection retrieval method
          def connection_with_magic
            db_charmer_remapped_connection || db_charmer_model_connection_proxy || connection_without_magic
          end
          alias_method_chain :connection, :magic

          def connection_pool_with_magic
            if connection.respond_to?(:abstract_connection_class)
              connection_handler.retrieve_connection_pool(connection.abstract_connection_class) || connection_pool_without_magic
            else
              connection_pool_without_magic
            end
          end
          alias_method_chain :connection_pool, :magic
        end
      end

      #-----------------------------------------------------------------------------------------------------------------
      def coerce_to_connection_proxy(conn, should_exist = true)
        return nil if conn.nil?

        if conn.respond_to?(:db_charmer_connection_proxy)
          return conn.db_charmer_connection_proxy
        end

        if conn.kind_of?(Symbol) || conn.kind_of?(String)
          return DbCharmer::ConnectionFactory.connect(conn, should_exist)
        end

        if conn.kind_of?(Hash)
          conn = conn.symbolize_keys
          raise ArgumentError, "Missing required :connection_name parameter" unless conn[:connection_name]
          return DbCharmer::ConnectionFactory.connect_to_db(conn[:connection_name], conn)
        end

        if conn.kind_of?(::ActiveRecord::ConnectionAdapters::AbstractAdapter) || conn.kind_of?(DbCharmer::Sharding::StubConnection)
          return conn
        end

        raise "Unsupported connection type: #{conn.class}"
      end

      #-----------------------------------------------------------------------------------------------------------------
      def switch_connection_to(conn, should_exist = true)
        new_conn = coerce_to_connection_proxy(conn, should_exist)

        if db_charmer_connection_proxy.respond_to?(:set_real_connection)
          db_charmer_connection_proxy.set_real_connection(new_conn)
        end

        self.db_charmer_connection_proxy = new_conn
        self.hijack_connection!

        # self.reset_column_information
      end

    end
  end
end

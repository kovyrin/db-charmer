module DbCharmer
  module ActiveRecord
    module ClassAttributes
      @@db_charmer_opts = {}
      def db_charmer_opts=(opts)
        @@db_charmer_opts[self.name] = opts
      end

      def db_charmer_opts
        @@db_charmer_opts[self.name] || {}
      end

      #-----------------------------------------------------------------------------
      def db_charmer_connection_proxies
        Thread.current[:db_charmer_connection_proxies] ||= {}
      end

      def db_charmer_connection_proxy=(proxy)
        db_charmer_connection_proxies[self.name] = proxy
      end

      def db_charmer_connection_proxy
        db_charmer_connection_proxies[self.name]
      end

      #-----------------------------------------------------------------------------
      @@db_charmer_default_connections = {}
      def db_charmer_default_connection=(conn)
        @@db_charmer_default_connections[self.name] = conn
      end

      def db_charmer_default_connection
        @@db_charmer_default_connections[self.name]
      end

      #-----------------------------------------------------------------------------
      @@db_charmer_slaves = {}
      def db_charmer_slaves=(slaves)
        @@db_charmer_slaves[self.name] = slaves
      end

      def db_charmer_slaves
        @@db_charmer_slaves[self.name] || []
      end

      def db_charmer_random_slave
        return nil unless db_charmer_slaves.any?
        db_charmer_slaves[rand(db_charmer_slaves.size)]
      end

      #-----------------------------------------------------------------------------
      @@db_charmer_force_slave_reads = {}
      def db_charmer_force_slave_reads=(force)
        @@db_charmer_force_slave_reads[self.name] = force
      end

      def db_charmer_force_slave_reads
        @@db_charmer_force_slave_reads[self.name]
      end

      # Slave reads are used in two cases:
      #  - per-model slave reads are enabled (see db_magic method for more details)
      #  - global slave reads enforcing is enabled (in a controller action)
      def db_charmer_force_slave_reads?
        db_charmer_force_slave_reads || DbCharmer.force_slave_reads?
      end

      #-----------------------------------------------------------------------------
      def db_charmer_connection_levels
        Thread.current[:db_charmer_connection_levels] ||= Hash.new(0)
      end

      def db_charmer_connection_level=(level)
        db_charmer_connection_levels[self.name] = level
      end

      def db_charmer_connection_level
        db_charmer_connection_levels[self.name] || 0
      end

      def db_charmer_top_level_connection?
        db_charmer_connection_level.zero?
      end

      #-----------------------------------------------------------------------------
      def db_charmer_remapped_connection
        return nil unless db_charmer_top_level_connection?
        name = :master
        proxy = db_charmer_connection_proxy
        name = proxy.db_charmer_connection_name.to_sym if proxy

        remapped = db_charmer_database_remappings[name]
        remapped ? DbCharmer::ConnectionFactory.connect(remapped, true) : nil
      end

      def db_charmer_database_remappings
        Thread.current[:db_charmer_database_remappings] ||= Hash.new
      end

      def db_charmer_database_remappings=(mappings)
        raise "Mappings must be nil or respond to []" if mappings && (! mappings.respond_to?(:[]))
        Thread.current[:db_charmer_database_remappings] = mappings || {}
      end
    end
  end
end

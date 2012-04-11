module DbCharmer
  module ActiveRecord
    module DbMagic

      def db_magic(opt = {})
        # Make sure we could use our connections management here
        hijack_connection!

        # Should requested connections exist in the config?
        should_exist = opt.has_key?(:should_exist) ? opt[:should_exist] : DbCharmer.connections_should_exist?

        # Main connection management
        setup_connection_magic(opt[:connection], should_exist)

        # Set up slaves pool
        opt[:slaves] ||= []
        opt[:slaves] = [ opt[:slaves] ].flatten
        opt[:slaves] << opt[:slave] if opt[:slave]

        # Forced reads are enabled for all models by default, could be disabled by the user
        forced_slave_reads = opt.has_key?(:force_slave_reads) ? opt[:force_slave_reads] : true

        # Setup all the slaves related magic if needed
        setup_slaves_magic(opt[:slaves], forced_slave_reads, should_exist)

        # Setup inheritance magic
        setup_children_magic(opt)

        # Setup sharding if needed
        if opt[:sharded]
          raise ArgumentError, "Can't use sharding on a model with slaves!" if opt[:slaves].any?
          setup_sharding_magic(opt[:sharded])
        end
      end

    private

      def setup_children_magic(opt)
        self.db_charmer_opts = opt.clone

        unless self.respond_to?(:inherited_with_db_magic)
          class << self
            def inherited_with_db_magic(child)
              o = inherited_without_db_magic(child)
              child.db_magic(self.db_charmer_opts)
              o
            end
            alias_method_chain :inherited, :db_magic
          end
        end
      end

      def setup_sharding_magic(config)
        # Add sharding-specific methods
        self.extend(DbCharmer::ActiveRecord::Sharding)

        # Get configuration
        name = config[:sharded_connection] or raise ArgumentError, "No :sharded_connection!"
        # Assign sharded connection
        self.sharded_connection = DbCharmer::Sharding.sharded_connection(name)

        # Setup model default connection
        setup_connection_magic(sharded_connection.default_connection)
      end

      def setup_connection_magic(conn, should_exist = true)
        switch_connection_to(conn, should_exist)
        self.db_charmer_default_connection = conn
      end

      def setup_slaves_magic(slaves, force_slave_reads, should_exist = true)
        self.db_charmer_force_slave_reads = force_slave_reads

        # Initialize the slave connections list
        self.db_charmer_slaves = slaves.collect do |slave|
          coerce_to_connection_proxy(slave, should_exist)
        end
        return if db_charmer_slaves.empty?

        # Enable on_slave/on_master methods
        self.extend(DbCharmer::ActiveRecord::MultiDbProxy::MasterSlaveClassMethods)

        # Enable automatic master/slave queries routing (we have specialized versions on those modules for rails2/3)
        self.extend(DbCharmer::ActiveRecord::MasterSlaveRouting::ClassMethods)
        self.send(:include, DbCharmer::ActiveRecord::MasterSlaveRouting::InstanceMethods)
      end

    end
  end
end

module DbCharmer
  module DbMagic
    module ClassMethods
      def db_magic(opt = {})
        # Make sure we could use our connections management here
        hijack_connection!

        # Should requested connections exist in the config?
        should_exist = opt[:should_exist] || DbCharmer.connections_should_exist?

        # Main connection management
        setup_connection_magic(opt[:connection], should_exist) if opt[:connection]

        # Set up slaves pool
        opt[:slaves] ||= []
        opt[:slaves] << opt[:slave] if opt[:slave]
        setup_slaves_magic(opt[:slaves], should_exist) if opt[:slaves].any?

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

        def self.inherited(child)
          child.db_magic(self.db_charmer_opts)
          super
        end
      end

      # FIXME: Need to make sure models won't work w/o a connection switching call
      # ... possible option is to set a dummy erroring default connection here...
      def setup_sharding_magic(config)
        self.extend(DbCharmer::Sharding::ClassMethods)
        name = config[:sharded_connection] or raise ArgumentError, "No :sharded_connection!"
        self.sharded_connection = DbCharmer::Sharding.sharded_connection(name)
      end

      def setup_connection_magic(conn, should_exist = false)
        switch_connection_to(conn, should_exist)
      end

      def setup_slaves_magic(slaves, should_exist = false)
        self.db_charmer_slaves = slaves.collect do |slave|
          coerce_to_connection_proxy(slave, should_exist)
        end

        self.extend(DbCharmer::FinderOverrides::ClassMethods)
        self.send(:include, DbCharmer::FinderOverrides::InstanceMethods)
        self.extend(DbCharmer::MultiDbProxy::MasterSlaveClassMethods)
      end
    end
  end
end


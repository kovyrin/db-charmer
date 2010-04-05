module DbCharmer
  module DbMagic
    module ClassMethods
      def db_magic(opt = {})
        # Make sure we could use our connections management here
        hijack_connection!

        # Should requested connections exist in the config?
        should_exist = opt[:should_exist] || DbCharmer.connections_should_exist?

        # Main connection management
        setup_connection_magic(opt[:connection], should_exist)

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

          # If method supports shards enumeration, get the first shard
          conns = sharded_connection.shard_connections || []
          real_conn = conns.first

          # If connection we do not have real connection yet, try to use the default one
          real_conn ||= sharded_connection.sharder.shard_for_key(:default) if sharded_connection.support_default_shard?

          # Create stub connection
          real_conn = coerce_to_connection_proxy(real_conn, DbCharmer.connections_should_exist?) if real_conn
          stub_conn = DbCharmer::StubConnection.new(real_conn)

          # ... and set it as the default one for this model
          setup_connection_magic(stub_conn)
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

      def setup_sharding_magic(config)
        self.extend(DbCharmer::Sharding::ClassMethods)
        name = config[:sharded_connection] or raise ArgumentError, "No :sharded_connection!"
        self.sharded_connection = DbCharmer::Sharding.sharded_connection(name)
      end

      def setup_connection_magic(conn, should_exist = false)
        switch_connection_to(conn, should_exist)
        self.db_charmer_default_connection = conn
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


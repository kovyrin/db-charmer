module DbCharmer
  module DbMagic
    module ClassMethods
      def db_magic(opt = {})
        # Make sure we could use our connections management here
        hijack_connection!

        # Should requested connections exist in the config?
        should_exist = opt[:should_exist] || DbCharmer.connections_should_exist?

        # Main connection management
        db_magic_connection(opt[:connection], should_exist) if opt[:connection]

        # Set up slaves pool
        opt[:slaves] ||= []
        opt[:slaves] << opt[:slave] if opt[:slave]
        db_magic_slaves(opt[:slaves], should_exist) if opt[:slaves].any?
        
        # Setup inheritance magic
        setup_children_magic(opt)
      end

    private

      def setup_children_magic(opt)
        self.db_charmer_opts = opt.clone
        
        def self.inherited(child)
          child.db_magic(self.db_charmer_opts)
          super
        end
      end

      def db_magic_connection(conn, should_exist = false)
        switch_connection_to(conn, should_exist)
      end

      def db_magic_slaves(slaves, should_exist = false)
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

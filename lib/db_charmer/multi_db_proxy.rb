module DbCharmer
  module MultiDbProxy
    class OnDbProxy < BlankSlate
      def initialize(model_class, slave)
        @model = model_class
        @slave = slave
      end

    private

      def method_missing(meth, *args, &block)
        @model.on_db(@slave) do |m|
          m.__send__(meth, *args, &block)
        end
      end
    end

    module ClassMethods
      def on_db(con, proxy_target = nil)
        proxy_target ||= self
        
        # Chain call
        return OnDbProxy.new(proxy_target, con) unless block_given?

        # Block call
        begin
          self.db_charmer_connection_level += 1
          old_proxy = db_charmer_connection_proxy
          switch_connection_to(con, DbCharmer.migration_connections_should_exist?)
          yield(proxy_target)
        ensure
          switch_connection_to(old_proxy)
          self.db_charmer_connection_level -= 1
        end
      end
    end
    
    module MasterSlaveClassMethods
      def on_slave(con = nil, proxy_target = nil, &block)
        con ||= db_charmer_random_slave
        raise ArgumentError, "No slaves found in the class and no slave connection given" unless con
        on_db(con, proxy_target, &block)
      end

      def on_master(proxy_target = nil, &block)
        on_db(nil, proxy_target, &block)
      end
    end
  end
end

module DbCharmer
  module MultiDbProxy
    class OnDbProxy < BlankSlate
      def initialize(model_class, slave_class)
        @model = model_class
        @slave = slave_class
      end

    private

      def method_missing(meth, *args, &block)
        @model.on_db(@slave) do |m|
          m.__send__(meth, *args, &block)
        end
      end
    end
    
    module ClassMethods
      def on_db(con)
        # Chain call
        return OnDbProxy.new(self, con) unless block_given?
        
        # Block call
        begin
          old_proxy = db_charmer_connection_proxy
          switch_connection_to(con, DbCharmer.migration_connections_should_exist?)
          yield(self)
        ensure
          switch_connection_to(old_proxy)
        end
      end
      
      def on_slave(con = nil, &block)
        con ||= db_charmer_random_slave
        raise ArgumentError, "No slaves found in the class and no slave connection given" unless con
        on_db(con, &block)
      end
    end
  end
end

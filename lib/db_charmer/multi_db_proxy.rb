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
        # Get a connection proxy
        connection = coerce_to_connection_proxy(con)

        # Chain call
        return OnDbProxy.new(self, connection) unless block_given?
        
        # Block call
        begin
          old_proxy = db_charmer_connection_proxy
          switch_connection_to(connection, DbCharmer.migration_connections_should_exist?)
          yield
        ensure
          switch_connection_to(old_proxy)
        end
      end
    end
  end
end
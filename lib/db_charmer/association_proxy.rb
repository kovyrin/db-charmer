module DbCharmer
  module AssociationProxy
    module InstanceMethods
      def on_db(con, &block)
        @reflection.klass.on_db(con, self, &block)
      end

      def on_slave(con = nil, &block)
        @reflection.klass.on_slave(con, self, &block)
      end

      def on_master(&block)
        @reflection.klass.on_master(self, &block)
      end
    end
  end
end

module DbCharmer
  module AssociationProxy
    module InstanceMethods
      def on_db(con, &block)
        @reflection.klass.on_db(con, self, &block)
      end
    end
  end
end


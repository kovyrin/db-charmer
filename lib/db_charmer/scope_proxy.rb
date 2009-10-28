module DbCharmer
  module ScopeProxy
    module InstanceMethods
      def on_db(con, proxy_target = nil, &block)
        proxy_target ||= self
        proxy_scope.on_db(con, self, &block)
      end

      def on_slave(con = nil, &block)
        proxy_scope.on_slave(con, self, &block)
      end

      def on_master(&block)
        proxy_scope.on_master(self, &block)
      end
    end
  end
end

module DbCharmer
  module ActiveRecordExtensions
    module ClassMethods
      def establish_connection_if_exists(name)
        config = configurations[RAILS_ENV][name.to_s]
        establish_connection(config) if config
      end
      
      @@connection_proxies = {}
      def connection_proxy=(proxy)
        @@connection_proxies[self.to_s] = proxy
      end

      def connection_proxy
        @@connection_proxies[self.to_s]
      end
      
      def connection
        connection_proxy || super
      end
    end
  end
end

module DbCharmer
  module Sharding
    module ClassMethods
      def self.extended(model)
        model.cattr_accessor(:sharded_connection)
      end
      
      def shard_for(key, proxy_target = nil, &block)
        con = sharded_connection.sharder.shard_for_key(key)
        on_db(con, proxy_target, &block)
      end
    end
    
    #-------------------------------------------------------------
    @@sharded_connections = {}
    
    def self.register_connection(config)
      name = config[:name] or raise ArgumentError, "No :name in connection!"
      @@sharded_connections[name] = DbCharmer::Sharding::Connection.new(config)
    end
    
    def self.sharded_connection(name)
      @@sharded_connections[name] or raise ArgumentError, "Invalid sharded connection name!"
    end
  end
end

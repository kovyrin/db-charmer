module DbCharmer
  module Sharding
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


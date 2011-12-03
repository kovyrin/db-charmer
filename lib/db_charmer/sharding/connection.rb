module DbCharmer
  module Sharding
    class Connection
      attr_accessor :config, :sharder

      def initialize(config)
        @config = config
        @sharder = self.instantiate_sharder
      end

      def instantiate_sharder
        raise ArgumentError, "No :method passed!" unless config[:method]
        sharder_class_name = "DbCharmer::Sharding::Method::#{config[:method].to_s.classify}"
        sharder_class = sharder_class_name.constantize
        sharder_class.new(config)
      end

      def shard_connections
        sharder.respond_to?(:shard_connections) ? sharder.shard_connections : nil
      end

      def support_default_shard?
        sharder.respond_to?(:support_default_shard?) && sharder.support_default_shard?
      end

      def default_connection
        @default_connection ||= DbCharmer::Sharding::StubConnection.new(self)
      end
    end
  end
end

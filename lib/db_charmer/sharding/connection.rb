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
    end
  end
end
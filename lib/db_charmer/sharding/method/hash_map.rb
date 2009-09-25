module DbCharmer
  module Sharding
    module Method
      class HashMap
        attr_accessor :map
        
        def initialize(config)
          @map = config[:map] or raise ArgumentError, "No :map defined!"
        end

        def shard_for_key(key)
          res = map[key] || map[:default]
          raise ArgumentError, "Invalid key value, no shards found for this key!" unless res
          return res
        end
        
      end
    end
  end
end
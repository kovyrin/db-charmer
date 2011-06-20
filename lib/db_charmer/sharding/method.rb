module DbCharmer
  module Sharding
    module Method
      autoload :Range, 'db_charmer/sharding/method/range'
      autoload :HashMap, 'db_charmer/sharding/method/hash_map'
      autoload :DbBlockMap, 'db_charmer/sharding/method/db_block_map'
      autoload :DbBlockGroupMap, 'db_charmer/sharding/method/db_block_group_map'
    end
  end
end
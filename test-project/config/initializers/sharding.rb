# Range-based shards for testing

TEXTS_SHARDING_RANGES = {
  0...100   => :shard1,
  100..200  => :shard2,
  :default  => :shard3
}

DbCharmer::Sharding.register_connection(
  :name => :texts,
  :method => :range,
  :ranges => TEXTS_SHARDING_RANGES
)

#------------------------------------------------
# Db blocks map sharding for testing

SOCIAL_SHARDING = DbCharmer::Sharding.register_connection(
  :name => :social,
  :method => :db_block_map,
  :block_size => 10,
  :map_table => :event_shards_map,
  :shards_table => :event_shards_info,
  :connection => :social_shard_info
)

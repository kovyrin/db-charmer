class RangeShardedModel < ActiveRecord::Base
  db_magic :sharded => {
    :key => :id,
    :sharded_connection => :texts
  }
end


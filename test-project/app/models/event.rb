class Event < ActiveRecord::Base
  self.table_name = :timeline_events

  db_magic :sharded => {
    :key => :to_uid,
    :sharded_connection => :social
  }
end

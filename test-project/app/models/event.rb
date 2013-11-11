class Event < ActiveRecord::Base
  attr_accessible :from_uid, :to_uid, :original_created_at, :event_type, :event_data

  self.table_name = :timeline_events

  db_magic :sharded => {
    :key => :to_uid,
    :sharded_connection => :social
  }
end

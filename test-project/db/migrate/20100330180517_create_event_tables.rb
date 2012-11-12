class CreateEventTables < ActiveRecord::Migration
  # In test environment just use database.yml-defined connections
  if Rails.env.test?
    db_magic :connections => [ :social_shard01, :social_shard02 ]
  else
    db_magic :sharded_connection => :social
  end

  def self.up
    sql = <<-SQL
      CREATE TABLE `timeline_events` (
        `event_id` int(11) NOT NULL AUTO_INCREMENT,
        `from_uid` int(11) NOT NULL,
        `to_uid` int(11) NOT NULL,
        `original_created_at` datetime NOT NULL,
        `event_type` int(11) NOT NULL,
        `event_data` text,
        `replies_count` int(11) NOT NULL DEFAULT '0',
        `parent_id` int(11) NOT NULL DEFAULT '0',
        `touched_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `on_profile` int(1) NOT NULL DEFAULT '0',
        PRIMARY KEY (`to_uid`,`parent_id`,`touched_at`,`event_id`),
        UNIQUE KEY `event_id_and_to_uid_key` (`event_id`,`to_uid`),
        KEY `on_profile_index` (`to_uid`,`on_profile`,`touched_at`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    SQL
    execute(sql)
  end

  def self.down
    drop_table :timeline_events
  end
end

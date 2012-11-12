class CreateShardingMapTables < ActiveRecord::Migration
  db_magic :connection => :social_shard_info

  def self.up
    create_table :event_shards_info, :force => true do |t|
      t.timestamps
      t.string  :db_host, :null => false
      t.integer :db_port, :null => false, :default => 3306
      t.string  :db_user, :null => false, :default => 'root'
      t.string  :db_pass, :null => false, :default => ''
      t.string  :db_name, :null => false
      t.boolean :open, :null => false, :default => false
      t.boolean :enabled, :null => false, :default => false
      t.integer :blocks_count, :null => false, :default => 0
    end

    add_index :event_shards_info, [:enabled, :open, :blocks_count], :name => "alloc"

    create_table :event_shards_map, :id => false, :force => true do |t|
      t.integer :start_id, :null => false
      t.integer :end_id, :null => false
      t.integer :shard_id, :null => false
      t.integer :block_size, :null => false, :default => 0
      t.timestamps
    end

    add_index :event_shards_map, [:start_id, :end_id], :unique => true
    add_index :event_shards_map, :shard_id
  end

  def self.down
    drop_table :event_shards_map
    drop_table :event_shards_info
  end
end

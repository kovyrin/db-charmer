class CreateLogRecords < ActiveRecord::Migration
  db_magic :connection => :logs

  def self.up
    create_table :log_records do |t|
      t.integer :user_id
      t.string :level
      t.string :message
      t.timestamps
    end
  end

  def self.down
    drop_table :log_records
  end
end

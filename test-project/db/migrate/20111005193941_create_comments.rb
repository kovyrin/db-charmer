class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.string  :commentable_type, :null => false
      t.integer :commentable_id,   :null => false
      t.text    :body,             :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end

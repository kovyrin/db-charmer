class CreateCategoriesPosts < ActiveRecord::Migration
  def self.up
    create_table :categories_posts, :id => false do |t|
      t.integer :post_id
      t.integer :category_id
    end
  end

  def self.down
    drop_table :categories_posts
  end
end

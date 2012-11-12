class CreateCategoriesPosts < ActiveRecord::Migration
  def self.up
    pk_in_join_table = !DbCharmer.rails3?
    create_table :categories_posts, :id => pk_in_join_table do |t|
      t.integer :post_id
      t.integer :category_id
    end
  end

  def self.down
    drop_table :categories_posts
  end
end

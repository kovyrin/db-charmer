class Post < ActiveRecord::Base
  attr_accessible :title, :user_id

  DB_MAGIC_DEFAULT_PARAMS = { :slave => :slave01, :force_slave_reads => false }
  db_magic DB_MAGIC_DEFAULT_PARAMS

  belongs_to :user
  has_and_belongs_to_many :categories

  if DbCharmer.rails4?
    scope :windows_posts, lambda { where("title like '%win%'") }
    scope :dummy_scope, lambda { where("1") }
  else
    scope :windows_posts, :conditions => "title like '%win%'"
    scope :dummy_scope, :conditions => '1'
  end
end

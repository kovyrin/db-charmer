class Post < ActiveRecord::Base
  DB_MAGIC_DEFAULT_PARAMS = { :slave => :slave01, :force_slave_reads => false }
  db_magic DB_MAGIC_DEFAULT_PARAMS

  belongs_to :user
  has_and_belongs_to_many :categories

  def self.define_scope(*args, &block)
    scope(*args, &block)
  end

  define_scope :windows_posts, :conditions => "title like '%win%'"
  define_scope :dummy_scope, :conditions => '1'
end

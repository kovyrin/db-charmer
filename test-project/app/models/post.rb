class Post < ActiveRecord::Base
  db_magic :slave => :slave01, :force_slave_reads => false

  belongs_to :user
  has_and_belongs_to_many :categories

  def self.define_scope(*args, &block)
    if DbCharmer.rails3?
      scope(*args, &block)
    else
      named_scope(*args, &block)
    end
  end

  define_scope :windows_posts, :conditions => "title like '%win%'"
  define_scope :dummy_scope, :conditions => '1'
end

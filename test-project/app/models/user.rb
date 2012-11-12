class User < ActiveRecord::Base
  has_many :posts
  has_many :log_records
  has_one :avatar
end

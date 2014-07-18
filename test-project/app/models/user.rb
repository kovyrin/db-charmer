class User < ActiveRecord::Base
  attr_accessible :login

  has_many :posts
  has_many :log_records
  has_one :avatar
end

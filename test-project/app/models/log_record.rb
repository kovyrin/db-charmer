class LogRecord < ActiveRecord::Base
  db_magic :connection => :logs
  belongs_to :user
end

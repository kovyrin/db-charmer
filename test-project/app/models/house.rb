class House < ActiveRecord::Base
  db_magic :slave => :slave01, :force_slave_reads => false
end

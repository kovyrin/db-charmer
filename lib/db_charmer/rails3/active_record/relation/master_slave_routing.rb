module DbCharmer
  module ActiveRecord
    module Relation
      module MasterSlaveRouting
        SLAVE_METHODS = [ :to_a ]

        MASTER_METHODS = [
          :create,
          :create!,
          :update_all,
          :update,
          :destroy_all,
          :destroy,
          :delete_all,
          :delete,
          :reload,
          :update_counters
        ]

      end
    end
  end
end

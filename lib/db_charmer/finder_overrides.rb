module DbCharmer
  module FinderOverrides
    module ClassMethods
      SLAVE_METHODS = [ :find_by_sql, :count_by_sql ]

      SLAVE_METHODS.each do |slave_method|
        class_eval <<-EOF
          def #{slave_method}(*args, &block)
            first_level_on_slave do
              super(*args, &block)
            end
          end
        EOF
      end
    
    private
    
      def first_level_on_slave
        if db_charmer_top_level_connection?
          on_slave { yield }
        else
          yield          
        end
      end
    end
    
    module InstanceMethods
      def reload(*args, &block)
        on_master do 
          super(*args, &block)
        end
      end
    end
  end
end

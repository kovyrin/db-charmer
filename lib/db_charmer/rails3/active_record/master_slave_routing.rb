module DbCharmer
  module ActiveRecord
    module MasterSlaveRouting

      module ClassMethods
        SLAVE_METHODS = [ :find_by_sql, :count_by_sql ]
        MASTER_METHODS = [ ] # I don't know any methods in AR::Base that change data directly w/o going to the relation object

        SLAVE_METHODS.each do |slave_method|
          class_eval <<-EOF, __FILE__, __LINE__ + 1
            def #{slave_method}(*args, &block)
              first_level_on_slave do
                super(*args, &block)
              end
            end
          EOF
        end

        MASTER_METHODS.each do |master_method|
          class_eval <<-EOF, __FILE__, __LINE__ + 1
            def #{master_method}(*args, &block)
              on_master do
                super(*args, &block)
              end
            end
          EOF
        end
      end

      module InstanceMethods
        MASTER_METHODS = [ :reload ]

        MASTER_METHODS.each do |master_method|
          class_eval <<-EOF, __FILE__, __LINE__ + 1
            def #{master_method}(*args, &block)
              self.class.on_master do
                super(*args, &block)
              end
            end
          EOF
        end
      end

    end
  end
end

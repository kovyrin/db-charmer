module DbCharmer
  module ActiveRecord
    module Relation
      module Connection

        def self.included(base)
          base.send(:attr_accessor, :db_charmer_connection)
          base.alias_method_chain :to_a, :db_charmer
          base.alias_method_chain :calculate, :db_charmer
        end

        def on_db(con)
          old_connection = db_charmer_connection
          self.db_charmer_connection = con
          clone
        ensure
          self.db_charmer_connection = old_connection
        end

        def connection
          @klass.on_db(db_charmer_connection).connection
        end

        def to_a_with_db_charmer(*args, &block)
          @klass.on_db(db_charmer_connection) do
            to_a_without_db_charmer(*args, &block)
          end
        end

        def calculate_with_db_charmer(*args, &block)
          @klass.on_db(db_charmer_connection) do
            calculate_without_db_charmer(*args, &block)
          end
        end

      end
    end
  end
end

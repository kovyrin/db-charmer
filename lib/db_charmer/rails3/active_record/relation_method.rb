module DbCharmer
  module ActiveRecord
    module RelationMethod

      def self.extended(base)
        class << base
          alias_method_chain :relation, :db_charmer
        end
      end

      def relation_with_db_charmer(*args, &block)
        relation_without_db_charmer(*args, &block).tap do |rel|
          rel.db_charmer_connection = self.connection
        end
      end

    end
  end
end

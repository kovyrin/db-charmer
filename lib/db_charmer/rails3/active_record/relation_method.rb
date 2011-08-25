module DbCharmer
  module ActiveRecord
    module RelationMethod

      def self.extended(base)
        class << base
          alias_method_chain :relation, :db_charmer
          alias_method_chain :arel_engine, :db_charmer
        end
      end

      # Create a relation object and initialize its default connection
      def relation_with_db_charmer(*args, &block)
        puts "RELATION"
        relation_without_db_charmer(*args, &block).tap do |rel|
          rel.db_charmer_connection = self.connection
          rel.db_charmer_enable_slaves = self.db_charmer_slaves.any?
          puts "RELATION slaves => #{rel.db_charmer_enable_slaves}"

          rel.db_charmer_connection_is_forced = !db_charmer_top_level_connection?
          puts "RELATION forced => #{rel.db_charmer_connection_is_forced}"
        end
      end

      # Use the model itself an engine for Arel, do not fall back to AR::Base
      def arel_engine_with_db_charmer(*)
        self
      end

    end
  end
end

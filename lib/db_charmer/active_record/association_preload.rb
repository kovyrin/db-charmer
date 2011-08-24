module DbCharmer
  module ActiveRecord
    module AssociationPreload
      ASSOCIATION_TYPES = [ :has_one, :has_many, :belongs_to, :has_and_belongs_to_many ]

      def self.extended(base)
        ASSOCIATION_TYPES.each do |association_type|
          base.class_eval <<-EOF, __FILE__, __LINE__ + 1
            def self.preload_#{association_type}_association(records, reflection, preload_options = {})
              if self.db_charmer_top_level_connection? || self.db_charmer_default_connection != reflection.klass.db_charmer_default_connection
                return super(records, reflection, preload_options)
              end
              reflection.klass.on_db(self) do
                super(records, reflection, preload_options)
              end
            end
          EOF
        end
      end
    end
  end
end

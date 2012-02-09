module DbCharmer
  module ActiveRecord
    module Preloader
      module HasAndBelongsToMany
        extend ActiveSupport::Concern
        included do
          alias_method_chain :records_for, :db_magic
        end

        def records_for_with_db_magic(ids)
          if model.db_charmer_top_level_connection? || reflection.options[:polymorphic] ||
              model.db_charmer_default_connection != klass.db_charmer_default_connection
            records_for_without_db_magic(ids)
          else
            klass.on_db(model) do
              records_for_without_db_magic(ids)
            end
          end
        end
      end
    end
  end
end

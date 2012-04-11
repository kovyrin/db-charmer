module DbCharmer
  module ActiveRecord
    module Preloader
      module Association
        extend ActiveSupport::Concern
        included do
          alias_method_chain :build_scope, :db_magic
        end

        def build_scope_with_db_magic
          if model.db_charmer_top_level_connection? || reflection.options[:polymorphic] ||
              model.db_charmer_default_connection != klass.db_charmer_default_connection
            build_scope_without_db_magic
          else
            build_scope_without_db_magic.on_db(model)
          end
        end
      end
    end
  end
end

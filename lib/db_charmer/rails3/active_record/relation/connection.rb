module DbCharmer
  module ActiveRecord
    module Relation
      module Connection

        # All the methods that could be querying the database
        SLAVE_METHODS = [ :calculate, :exists?, :to_a ]
        MASTER_METHODS = [ :delete, :delete_all, :destroy, :destroy_all, :reload, :update, :update_all ]
        ALL_METHODS = SLAVE_METHODS + MASTER_METHODS

        # Define the default relation connection + override all the query methods here
        def self.included(base)
          base.send(:attr_accessor, :db_charmer_connection)

          ALL_METHODS.each do |meth|
            base.alias_method_chain meth, :db_charmer
          end

          # Special case: for normal selects we go to the slave, but for selects with :lock => true we should use master
          base.alias_method_chain :find, :db_charmer
        end

        # Connection switching (changes the default relation connection)
        def on_db(con)
          old_connection = db_charmer_connection
          self.db_charmer_connection = con
          clone
        ensure
          self.db_charmer_connection = old_connection
        end

        # Make sure we get the right connection here
        def connection
          @klass.on_db(db_charmer_connection).connection
        end

        # Switch the model to default relation connection
        def switch_connection_for_method(method, preferred_destination = nil)
          @klass.on_db(db_charmer_connection) do
            yield
          end
        end

        # For normal selects we go to the slave, but for selects with :lock => true we should use master
        def find_with_db_charmer(*args, &block)
          options = args.last
          preferred_destination =  (options.is_a?(Hash) && options[:lock]) ? :master : :slave
          switch_connection_for_method(:find, preferred_destination) do
            find_without_db_charmer(*args, &block)
          end
        end

        # Need this to mimick alias_method_chain name generation (exists? => exists_with_db_charmer?)
        def self.aliased_method_name(target, with)
          aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
          "#{aliased_target}_#{with}_db_charmer#{punctuation}"
        end

        # Override all the query methods here
        ALL_METHODS.each do |method|
          class_eval <<-EOF, __FILE__, __LINE__ + 1
            def #{aliased_method_name method, :with}(*args, &block)
              switch_connection_for_method(:#{method.to_s}) do
                #{aliased_method_name method, :without}(*args, &block)
              end
            end
          EOF
        end

      end
    end
  end
end

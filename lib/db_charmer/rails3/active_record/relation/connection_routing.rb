module DbCharmer
  module ActiveRecord
    module Relation
      module ConnectionRouting

        # All the methods that could be querying the database
        SLAVE_METHODS = [ :calculate, :exists? ]
        MASTER_METHODS = [ :delete, :delete_all, :destroy, :destroy_all, :reload, :update, :update_all ]
        ALL_METHODS = SLAVE_METHODS + MASTER_METHODS

        DB_CHARMER_ATTRIBUTES = [ :db_charmer_connection, :db_charmer_connection_is_forced, :db_charmer_enable_slaves ]

        # Define the default relation connection + override all the query methods here
        def self.included(base)
          init_attributes(base)
          init_routing(base)
        end

        # Define our attributes + spawn methods shit needs to be changed to make sure our accessors are copied over to the new instances
        def self.init_attributes(base)
          DB_CHARMER_ATTRIBUTES.each do |attr|
            base.send(:attr_accessor, attr)
          end

          # Override spawn methods
          base.alias_method_chain :except, :db_charmer
          base.alias_method_chain :only, :db_charmer
        end

        # Override all query methods
        def self.init_routing(base)
          ALL_METHODS.each do |meth|
            base.alias_method_chain meth, :db_charmer
          end

          # Special case: for normal selects we go to the slave, but for selects with a lock we should use master
          base.alias_method_chain :to_a, :db_charmer
        end

        # Copy db_charmer attributes in addition to what they're copying
        def except_with_db_charmer(*args)
          except_without_db_charmer(*args).tap do |result|
            copy_db_charmer_options(self, result)
          end
        end

        # Copy db_charmer attributes in addition to what they're copying
        def only_with_db_charmer(*args)
          only_without_db_charmer(*args).tap do |result|
            copy_db_charmer_options(self, result)
          end
        end

        # Copy our accessors from one instance to another
        def copy_db_charmer_options(src, dst)
          DB_CHARMER_ATTRIBUTES.each do |attr|
            dst.send("#{attr}=".to_sym, src.send(attr))
          end
        end

        # Connection switching (changes the default relation connection)
        def on_db(con, &block)
          if block_given?
            @klass.on_db(con, &block)
          else
            clone.tap do |result|
              result.db_charmer_connection = con
              result.db_charmer_connection_is_forced = true
            end
          end
        end

        # Make sure we get the right connection here
        def connection
          @klass.on_db(db_charmer_connection).connection
        end

        # Selects preferred destination (master/slave/default) for a query
        def select_destination(method, recommendation = :default)
          # If this relation was created within a forced connection block (e.g Model.on_db(:foo).relation)
          # Then we should use that connection everywhere except cases when a model is slave-enabled
          # in those cases DML queries go to the master
          if db_charmer_connection_is_forced
            return :master if db_charmer_enable_slaves && MASTER_METHODS.member?(method)
            return :default
          end

          # If this relation is created from a slave-enabled model, let's do the routing if possible
          if db_charmer_enable_slaves
            return :slave if SLAVE_METHODS.member?(method)
            return :master if MASTER_METHODS.member?(method)
          else
            # Make sure we do not use recommended destination
            recommendation = :default
          end

          # If nothing else came up, let's use the default or recommended connection
          return recommendation
        end

        # Switch the model to default relation connection
        def switch_connection_for_method(method, recommendation = nil)
          # Choose where to send the query
          destination ||= select_destination(method, recommendation)

          # What method to use
          on_db_method = [ :on_db, db_charmer_connection ]
          on_db_method = :on_master if destination == :master
          on_db_method = :first_level_on_slave if destination == :slave

          # Perform the query
          @klass.send(*on_db_method) do
            yield
          end
        end

        # For normal selects we go to the slave, but for selects with a lock we should use master
        def to_a_with_db_charmer(*args, &block)
          preferred_destination = :slave
          preferred_destination = :master if lock_value

          switch_connection_for_method(:to_a, preferred_destination) do
            to_a_without_db_charmer(*args, &block)
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

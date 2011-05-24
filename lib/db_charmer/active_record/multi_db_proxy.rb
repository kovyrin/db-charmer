module DbCharmer
  module ActiveRecord
    module MultiDbProxy
      # Simple proxy class that switches connections and then proxies all the calls
      # This class is used to implement chained on_db calls
      class OnDbProxy < ActiveSupport::BasicObject
        # We need to do this because in Rails 2.3 BasicObject does not remove object_id method, which is stupid
        undef_method(:object_id) if instance_methods.member?('object_id')

        def initialize(proxy_target, slave)
          @proxy_target = proxy_target
          @slave = slave
        end

      private

        def method_missing(meth, *args, &block)
          # Switch connection and proxy the method call
          @proxy_target.on_db(@slave) do |proxy_target|
            res = proxy_target.__send__(meth, *args, &block)

            # If result is a scope/association, return a new proxy for it, otherwise return the result itself
            (res.proxy?) ? OnDbProxy.new(res, @slave) : res
          end
        end
      end

      module ClassMethods
        def on_db(con, proxy_target = nil)
          proxy_target ||= self

          # Chain call
          return OnDbProxy.new(proxy_target, con) unless block_given?

          # Block call
          begin
            self.db_charmer_connection_level += 1
            old_proxy = db_charmer_connection_proxy
            switch_connection_to(con, DbCharmer.connections_should_exist?)
            yield(proxy_target)
          ensure
            switch_connection_to(old_proxy)
            self.db_charmer_connection_level -= 1
          end
        end
      end

      module InstanceMethods
        def on_db(con, proxy_target = nil, &block)
          proxy_target ||= self
          self.class.on_db(con, proxy_target, &block)
        end
      end

      module MasterSlaveClassMethods
        def on_slave(con = nil, proxy_target = nil, &block)
          con ||= db_charmer_random_slave
          raise ArgumentError, "No slaves found in the class and no slave connection given" unless con
          on_db(con, proxy_target, &block)
        end

        def on_master(proxy_target = nil, &block)
          on_db(db_charmer_default_connection, proxy_target, &block)
        end
      end
    end
  end
end

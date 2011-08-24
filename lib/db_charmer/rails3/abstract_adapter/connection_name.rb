module DbCharmer
  module AbstractAdapter
    module ConnectionName

      # We use this proxy to push connection name down to instrumenters w/o monkey-patching the log method itself
      class InstrumenterDecorator < ActiveSupport::BasicObject
        def initialize(adapter, instrumenter)
          @adapter = adapter
          @instrumenter = instrumenter
        end

        def instrument(name, payload = {}, &block)
          payload[:connection_name] ||= @adapter.connection_name
          @instrumenter.instrument(name, payload, &block)
        end

        def method_missing(meth, *args, &block)
          @instrumenter.send(meth, *args, &block)
        end
      end

      def self.included(base)
        base.alias_method_chain :initialize, :connection_name
      end

      def connection_name
        raise "Can't find connection configuration!" unless @config
        @config[:connection_name]
      end

      def initialize_with_connection_name(*args)
        initialize_without_connection_name(*args)
        @instrumenter = InstrumenterDecorator.new(self, @instrumenter)
      end

    end
  end
end

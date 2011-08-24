module DbCharmer
  module ActiveRecord
    module LogSubscriber

      def self.included(base)
        base.send(:attr_accessor, :connection_name)
        base.alias_method_chain :sql, :connection_name
        base.alias_method_chain :debug, :connection_name
      end

      def sql_with_connection_name(event)
        self.connection_name = event.payload[:connection_name]
        sql_without_connection_name(event)
      end

      def debug_with_connection_name(msg)
        conn = connection_name ? color("  [#{connection_name}]", ActiveSupport::LogSubscriber::BLUE, true) : ''
        debug_without_connection_name(conn + msg)
      end

    end
  end
end

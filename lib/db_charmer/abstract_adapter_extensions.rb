module DbCharmer
  module AbstractAdapterExtensions
    module InstanceMethods
      def self.included(base)
        base.alias_method_chain :format_log_entry, :connection_name
      end

      def connection_name
        @connection_name
      end

      def connection_name=(name)
        @connection_name = name
      end

      def format_log_entry_with_connection_name(message, dump = nil)
        msg = connection_name ? "[#{connection_name}] " : ''
        msg << format_log_entry_without_connection_name(message, dump)
      end
    end
  end
end

module DbCharmer
  module AbstractAdapter
    module LogFormatting

      def self.included(base)
        base.alias_method_chain :format_log_entry, :connection_name
      end

      def connection_name
        raise "Can't find connection configuration!" unless @config
        @config[:connection_name]
      end

      # Rails 2.X specific logging method
      def format_log_entry_with_connection_name(message, dump = nil)
        msg = connection_name ? "[#{connection_name}] " : ''
        msg = "  \e[0;34;1m#{msg}\e[0m" if connection_name && ::ActiveRecord::Base.colorize_logging
        msg << format_log_entry_without_connection_name(message, dump)
      end

    end
  end
end

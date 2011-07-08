require 'pp'

module DbCharmer
  module ActiveRecord
    module QueryCache
      def cache_for_connections(conns, &block)
        return block.call if conns.empty?
        conn = conns.pop
        conn.cache do
          cache_for_connections(conns, &block)
        end
      end

      # Enable the query cache within the block if Active Record is configured.
      # We rewrite the original method here to do cache calls on all connections,
      # not only the default one as they do by default
      def cache(&block)
        if ::ActiveRecord::Base.configurations.blank?
          return yield
        else
          conns = ConnectionFactory.all_connections
          cache_for_connections(conns, &block)

          # FIXME: wondering why something like this does not work
          # conns.each do |conn|
          #   block = proc { conn.cache(&block) }
          # end
          # block.call
        end
      end

    end
  end
end
module DbCharmer
  module ActiveRecordExtensions
    module ClassMethods

      def establish_real_connection_if_exists(name, should_exist = false)
        config = configurations[RAILS_ENV][name.to_s]
        if should_exist && !config
          raise ArgumentError, "Invalid connection name (does not exist in database.yml): #{RAILS_ENV}/#{name}"
        end
        establish_connection(config) if config
      end
      
      #-----------------------------------------------------------------------------
      @@db_charmer_connection_proxies = {}
      def db_charmer_connection_proxy=(proxy)
        @@db_charmer_connection_proxies[self.to_s] = proxy
      end

      def db_charmer_connection_proxy
        @@db_charmer_connection_proxies[self.to_s]
      end
      
      #-----------------------------------------------------------------------------
      @@db_charmer_slaves = {}
      def db_charmer_slaves=(slaves)
        @@db_charmer_slaves[self.to_s] = slaves
      end

      def db_charmer_slaves
        @@db_charmer_slaves[self.to_s] || []
      end
      
      def db_charmer_random_slave
        return nil unless db_charmer_slaves.any?
        db_charmer_slaves[rand(db_charmer_slaves.size)]
      end

      #-----------------------------------------------------------------------------
      @@db_charmer_connection_levels = Hash.new(0)
      def db_charmer_connection_level=(level)
        @@db_charmer_connection_levels[self.to_s] = level
      end

      def db_charmer_connection_level
        @@db_charmer_connection_levels[self.to_s] || 0
      end
      
      def db_charmer_top_level_connection?
        db_charmer_connection_level.zero?
      end
      
      #-----------------------------------------------------------------------------
      def hijack_connection!
        # FIXME: make sure we do not do it more often then needed
#        puts "DEBUG: Hijacking connection for #{self.to_s}"
        class << self 
          def connection
            db_charmer_connection_proxy || super
          end
        end
      end
      
    end
  end
end

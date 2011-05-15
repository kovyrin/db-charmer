module DbCharmer
  module ActionController
    module ForceSlaveReads

      module ClassMethods
        @@db_charmer_force_slave_reads_actions = {}
        def force_slave_reads(params)
          @@db_charmer_force_slave_reads_actions[self.name] = {
            :except => params[:except] ? [*params[:except]].map(&:to_s) : [],
            :only => params[:only] ? [*params[:only]].map(&:to_s) : []
          }
        end

        def force_slave_reads_options
          @@db_charmer_force_slave_reads_actions[self.name]
        end

        def force_slave_reads_action?(name = nil)
          name = name.to_s

          options = force_slave_reads_options
          # If no options were defined for this controller, all actions are not forced to use slaves
          return false unless options

          # Actions where force_slave_reads mode was turned off
          return false if options[:except].include?(name)

          # Only for these actions force_slave_reads was turned on
          return options[:only].include?(name) if options[:only].any?

          # If :except is not empty, we're done with the checks and rest of the actions are should force slave reads
          # Otherwise, all the actions are not in force_slave_reads mode
          options[:except].any?
        end
      end

      module InstanceMethods
        def self.included(base)
          base.alias_method_chain :perform_action, :forced_slave_reads
        end

        def force_slave_reads!
          @db_charmer_force_slave_reads = true
        end

        def dont_force_slave_reads!
          @db_charmer_force_slave_reads = false
        end

        def force_slave_reads?
          @db_charmer_force_slave_reads || self.class.force_slave_reads_action?(params[:action])
        end

      protected

        def perform_action_with_forced_slave_reads
          DbCharmer.with_controller(self) do
            perform_action_without_forced_slave_reads
          end
        end
      end

    end
  end
end

module DbCharmer
  module ActiveRecord
    module Migration
      module CommandRecorder
        def invert_on_db(args)
          [:replay_commands_on_db, [args.first, args[1].inverse]]
        end
      end
    end
  end
end
module DbCharmer
  module ActiveRecord
    module Migration
      module CommandRecorder
        def invert_on_db(args)
          [ :replay_commands_on_db, args ]
        end
      end
    end
  end
end
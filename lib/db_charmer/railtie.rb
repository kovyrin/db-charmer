module DbCharmer
  class Railtie < Rails::Railtie

    rake_tasks do
      load "db_charmer/tasks/database.rake"
    end

  end
end

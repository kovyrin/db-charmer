module DbCharmer
  class Railtie < Rails::Railtie

    rake_tasks do
      load "db_charmer/tasks/databases.rake"
    end

  end
end

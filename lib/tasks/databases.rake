namespace :db_charmer do
  namespace :create do
    desc 'Create all the local databases defined in config/database.yml'
    task :all => "db:load_config" do
      ::ActiveRecord::Base.configurations.each_value do |config|
        # Skip entries that don't have a database key, such as the first entry here:
        #
        #  defaults: &defaults
        #    adapter: mysql
        #    username: root
        #    password:
        #    host: localhost
        #
        #  development:
        #    database: blog_development
        #    <<: *defaults
        next unless config['database']
        # Only connect to local databases
        local_database?(config) { create_core_and_sub_database(config) }
      end
    end
  end

  desc 'Create the databases defined in config/database.yml for the current RAILS_ENV'
  task :create => "db:load_config" do
    create_core_and_sub_database(ActiveRecord::Base.configurations[RAILS_ENV])
  end

  def create_core_and_sub_database(config)
    create_database(config)
    config.each_value do | sub_config |
      next unless sub_config.is_a?(Hash)
      next unless sub_config['database']
      create_database(sub_config)
    end
  end

  namespace :drop do
    desc 'Drops all the local databases defined in config/database.yml'
    task :all => "db:load_config" do
      ::ActiveRecord::Base.configurations.each_value do |config|
        # Skip entries that don't have a database key
        next unless config['database']
        # Only connect to local databases
        local_database?(config) { drop_core_and_sub_database(config) }
      end
    end
  end

  desc 'Drops the database for the current RAILS_ENV'
  task :drop => "db:load_config" do
    config = ::ActiveRecord::Base.configurations[RAILS_ENV || 'development']
    begin
      drop_core_and_sub_database(config)
    rescue Exception => e
      puts "Couldn't drop #{config['database']} : #{e.inspect}"
    end
  end


  def local_database?(config, &block)
    if %w( 127.0.0.1 localhost ).include?(config['host']) || config['host'].blank?
      yield
    else
      puts "This task only modifies local databases. #{config['database']} is on a remote host."
    end
  end
end

def drop_core_and_sub_database(config)
  drop_database(config)
  config.each_value do | sub_config |
    next unless sub_config.is_a?(Hash)
    next unless sub_config['database']
    begin
      drop_database(sub_config)
    rescue
      $stderr.puts "#{config['database']} not exists"
    end
  end
end


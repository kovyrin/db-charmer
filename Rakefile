begin
  require 'jeweler'
  require './lib/db_charmer/version.rb'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'db-charmer'
    gemspec.summary = 'ActiveRecord Connections Magic'
    gemspec.description = 'ActiveRecord Connections Magic (slaves, multiple connections, etc)'
    gemspec.email = 'alexey@kovyrin.net'
    gemspec.homepage = 'http://github.com/kovyrin/db-charmer'
    gemspec.authors = ['Alexey Kovyrin']

    gemspec.version = DbCharmer::Version::STRING

    gemspec.add_dependency('activesupport', '~> 2.2')
    gemspec.add_dependency('activerecord', '~> 2.2')
    gemspec.add_dependency('actionpack', '~> 2.2')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler not available. Install it with: sudo gem install jeweler'
end

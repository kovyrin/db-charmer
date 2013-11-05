# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'db_charmer/version'

Gem::Specification.new do |s|
  s.name          = 'db-charmer'
  s.version       = DbCharmer::Version::STRING
  s.platform      = Gem::Platform::RUBY

  s.authors       = [ 'Oleksiy Kovyrin' ]
  s.email         = 'alexey@kovyrin.net'
  s.homepage      = 'http://dbcharmer.net'
  s.summary       = 'ActiveRecord Connections Magic (slaves, multiple connections, etc)'
  s.description   = 'DbCharmer is a Rails plugin (and gem) that could be used to manage AR model connections, implement master/slave query schemes, sharding and other magic features many high-scale applications need.'

  s.rdoc_options = [ '--charset=UTF-8' ]

  s.files         = Dir['lib/**/*'] + Dir['*.rb']
  s.files        += %w[ README.rdoc LICENSE CHANGES ]

  s.require_paths    = [ 'lib' ]
  s.extra_rdoc_files = [ 'LICENSE', 'README.rdoc' ]

  # Dependencies
  s.add_dependency 'activesupport', '<= 4.0.1'
  s.add_dependency 'activerecord', '<= 4.0.1'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'actionpack'
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] = 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false
  config.use_instantiated_fixtures  = false

  # Infer spec types from file locations (pre-rspec-3.0 behavior)
  config.infer_spec_type_from_file_location!

  # Raise errors on rspec deprecations
  config.raise_errors_for_deprecations!

  # Enable old and new syntaxes for expectations and mocks
  config.expect_with :rspec do |c|
    c.syntax = [ :should, :expect ]
  end
  config.mock_with :rspec do |c|
    c.syntax = [ :should, :expect ]
  end
end

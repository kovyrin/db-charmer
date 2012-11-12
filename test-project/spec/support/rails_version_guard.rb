RSpec.configure do |config|
  config.filter_run_excluding :rails => lambda { |requirement| !(Gem::Requirement.new(requirement) =~ Gem::Version.new(Rails.version)) }
end

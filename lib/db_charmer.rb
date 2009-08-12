module DbCharmer
  @@migration_connections_should_exist = Rails.env.production?
  mattr_accessor :migration_connections_should_exist

  def self.migration_connections_should_exist?
    !! migration_connections_should_exist
  end

  @@connections_should_exist = Rails.env.production?
  mattr_accessor :connections_should_exist

  def self.connections_should_exist?
    !! connections_should_exist
  end
end

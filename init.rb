require 'active_record'

# Enable misc AR extensions
ActiveRecord::Base.extend(DbCharmer::ActiveRecordExtensions::ClassMethods)

# Enable connections switching in AR
ActiveRecord::Base.extend(DbCharmer::ConnectionSwitch::ClassMethods)

# Enable connection proxy in AR
ActiveRecord::Base.extend(DbCharmer::MultiDbProxy::ClassMethods)

# Enable multi-db migrations
ActiveRecord::Migration.extend(DbCharmer::MultiDbMigrations::ClassMethods)

# Enable the magic
ActiveRecord::Base.extend(DbCharmer::DbMagic::ClassMethods)

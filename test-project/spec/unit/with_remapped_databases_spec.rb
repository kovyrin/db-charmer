require 'spec_helper'

describe "DbCharmer#with_remapped_databases" do
  before(:all) do
    DbCharmer.connections_should_exist = false
  end

  let(:logs_connection) { DbCharmer::ConnectionFactory.connect(:logs) }
  let(:slave_connection) { DbCharmer::ConnectionFactory.connect(:slave01) }
  let(:master_connection) { Avatar.connection }

  before :each do
    class User < ActiveRecord::Base
      db_magic :connection => :slave01
    end
  end

  def should_have_connection(model_class, connection)
    model_class.connection.object_id.should == connection.object_id
  end

  it "should remap the right connection" do
    should_have_connection(LogRecord, logs_connection)
    DbCharmer.with_remapped_databases(:logs => :slave01) do
      should_have_connection(LogRecord, slave_connection)
    end
    should_have_connection(LogRecord, logs_connection)
  end

  it "should not remap other connections" do
    should_have_connection(Avatar, master_connection)
    should_have_connection(User, slave_connection)
    DbCharmer.with_remapped_databases(:logs => :slave01) do
      should_have_connection(Avatar, master_connection)
      should_have_connection(User, slave_connection)
    end
    should_have_connection(Avatar, master_connection)
    should_have_connection(User, slave_connection)
  end

  it "should allow remapping multiple databases" do
    should_have_connection(Avatar, master_connection)
    should_have_connection(LogRecord, logs_connection)
    DbCharmer.with_remapped_databases(:master => :logs, :logs => :slave01) do
      should_have_connection(Avatar, logs_connection)
      should_have_connection(LogRecord, slave_connection)
    end
    should_have_connection(Avatar, master_connection)
    should_have_connection(LogRecord, logs_connection)
  end

  it "should remap the master connection when asked to, but not other connections" do
    should_have_connection(Avatar, master_connection)
    should_have_connection(User, slave_connection)
    should_have_connection(LogRecord, logs_connection)
    DbCharmer.with_remapped_databases(:master => :slave01) do
      should_have_connection(Avatar, slave_connection)
      should_have_connection(User, slave_connection)
      should_have_connection(LogRecord, logs_connection)
    end
    should_have_connection(Avatar, master_connection)
    should_have_connection(User, slave_connection)
    should_have_connection(LogRecord, logs_connection)
  end

  it "should not override connections that are explicitly specified" do
    DbCharmer.with_remapped_databases(:logs => :slave01) do
      should_have_connection(LogRecord, slave_connection)
      should_have_connection(LogRecord.on_db(:master), master_connection)
      LogRecord.on_db(:master) do
        should_have_connection(LogRecord, master_connection)
      end
      should_have_connection(LogRecord.on_db(:logs), logs_connection)
      LogRecord.on_db(:logs) do
        should_have_connection(LogRecord, logs_connection)
      end
      should_have_connection(LogRecord, slave_connection)
    end
  end

  it "should successfully run selects on the right database" do
    LogRecord.delete_all
    result = logs_connection.select_all("SELECT * FROM log_records")

    # Remap LogRecord connection to slave01 and make sure selects would go there (even though we do not have the table there)
    DbCharmer.with_remapped_databases(:logs => :slave01) do
      logs_connection.should_not_receive(:select_all)
      slave_connection.should_receive(:select_all).and_return(result)
      stub_columns_for_rails31 slave_connection
      LogRecord.all.should be_empty
    end
  end

  def unhijack!(klass)
    if klass.respond_to?(:connection_with_magic)
      klass.class_eval <<-END
        class << self
          undef_method(:connection_with_magic)
          alias_method(:connection, :connection_without_magic)
          undef_method(:connection_without_magic)

          undef_method(:connection_pool_with_magic)
          alias_method(:connection_pool, :connection_pool_without_magic)
          undef_method(:connection_pool_without_magic)
        end
      END
    end

    raise "Unable to unhijack #{klass.name}" if klass.respond_to?(:connection_with_magic)
  end

  it "should hijack connections only when necessary" do
    unhijack!(Category)

    Category.respond_to?(:connection_with_magic).should be(false)
    DbCharmer.with_remapped_databases(:logs => :slave01) do
      Category.respond_to?(:connection_with_magic).should be(false)
    end
    Category.respond_to?(:connection_with_magic).should be(false)

    DbCharmer.with_remapped_databases(:master => :slave01) do
      Category.respond_to?(:connection_with_magic).should be(true)
      should_have_connection(Category, slave_connection)
    end
  end
end

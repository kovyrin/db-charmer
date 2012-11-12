require 'spec_helper'

describe User do
  before(:each) do
    @valid_attributes = {
      :login => "value for login",
      :password => "value for password"
    }
    User.switch_connection_to(nil)
  end

  it "should create a new instance given valid attributes" do
    User.create!(@valid_attributes)
  end

  it "should create a new instance in a specified db" do
    # Just to make sure
    User.on_db(:user_master).connection.object_id.should_not == User.connection.object_id

    # Default connection should not be touched
    User.connection.should_not_receive(:insert)

    # Only specified connection receives an insert
    User.on_db(:user_master).connection.should_receive(:insert)

    # Test!
    User.on_db(:user_master).create!(@valid_attributes)
  end
end

require 'spec_helper'

describe Avatar do
  before(:each) do
    @valid_attributes = {
      :user_id => 1,
      :name => "value for name"
    }
  end

  it "should create a new instance given valid attributes" do
    Avatar.create!(@valid_attributes)
  end
end

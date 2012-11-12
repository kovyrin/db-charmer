require 'spec_helper'

describe LogRecord do
  before(:each) do
    @valid_attributes = {
      :level => "value for level",
      :message => "value for message"
    }
  end

  it "should create a new instance given valid attributes" do
    LogRecord.create!(@valid_attributes)
  end
end

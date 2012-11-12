require 'spec_helper'

describe DbCharmer::Sharding::Connection do
  describe "in constructor" do
    it "should not fail if method name is correct" do
      lambda { DbCharmer::Sharding::Connection.new(:name => :foo, :method => :range, :ranges => {}) }.should_not raise_error
    end

    it "should fail if method name is missing" do
      lambda { DbCharmer::Sharding::Connection.new(:name => :foo) }.should raise_error(ArgumentError)
    end

    it "should fail if method name is invalid" do
      lambda { DbCharmer::Sharding::Connection.new(:name => :foo, :method => :foo) }.should raise_error(NameError)
    end

    it "should instantiate a sharder class according to the :method value" do
      DbCharmer::Sharding::Method::Range.should_receive(:new)
      DbCharmer::Sharding::Connection.new(:name => :foo, :method => :range, :ranges => {})
    end
  end
end


require 'spec_helper'

describe "DbCharmer::Sharding" do
  describe "in register_connection method" do
    it "should raise an exception if passed config has no :name parameter" do
      lambda {
        DbCharmer::Sharding.register_connection(:method => :range, :ranges => { :default => :foo })
      }.should raise_error(ArgumentError)
    end

    it "should not raise an exception if passed config has all required params" do
      lambda {
        DbCharmer::Sharding.register_connection(:method => :range, :ranges => { :default => :foo }, :name => :foo)
      }.should_not raise_error
    end
  end

  describe "in sharded_connection method" do
    it "should raise an error for invalid connection names" do
      lambda { DbCharmer::Sharding.sharded_connection(:blah) }.should raise_error(ArgumentError)
    end
  end
end

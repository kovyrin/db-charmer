require 'spec_helper'

describe DbCharmer::Sharding::Method::Range do
  SHARDING_RANGES = {
    0...100   => :shard1,
    100..200  => :shard2,
    :default  => :shard3
  }

  before do
    @sharder = DbCharmer::Sharding::Method::Range.new(:ranges => SHARDING_RANGES)
  end

  describe "standard interface" do
    it "should respond to shard_for_id" do
      @sharder.should respond_to(:shard_for_key)
    end

    it "should return a shard name to be used for an key" do
      @sharder.shard_for_key(1).should be_kind_of(Symbol)
    end

    it "should support default shard" do
      @sharder.support_default_shard?.should be(true)
    end
  end

  describe "should correctly return shards for all ids in defined ranges" do
    [ 0, 1, 50, 99].each do |id|
      it "for #{id}" do
        @sharder.shard_for_key(id).should == :shard1
      end
    end

    [ 100, 101, 150, 199, 200].each do |id|
      it "for #{id}" do
        @sharder.shard_for_key(id).should == :shard2
      end
    end
  end

  describe "should correctly return shard for all ids outside the ranges if has a default" do
    [ 201, 500].each do |id|
      it "for #{id}" do
        @sharder.shard_for_key(id).should == :shard3
      end
    end
  end

  it "should raise an exception when there is no default shard and no ranges matched" do
    @sharder.ranges.delete(:default)
    lambda { @sharder.shard_for_key(500) }.should raise_error(ArgumentError)
  end
end

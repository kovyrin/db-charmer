require 'spec_helper'

describe DbCharmer::Sharding::Method::DbBlockMap do
  fixtures :event_shards_info, :event_shards_map

  before(:each) do
    @sharder = DbCharmer::Sharding::Method::DbBlockMap.new(
      :name => :social,
      :block_size => 10,
      :map_table => :event_shards_map,
      :shards_table => :event_shards_info,
      :connection => :social_shard_info
    )
    @conn = DbCharmer::ConnectionFactory.connect(:social_shard_info)
  end

  describe "standard interface" do
    it "should respond to shard_for_id" do
      @sharder.should respond_to(:shard_for_key)
    end

    it "should return a shard config to be used for a key" do
      @sharder.shard_for_key(1).should be_kind_of(Hash)
    end

    it "should have shard_connections method and return a list of db connections" do
      @sharder.shard_connections.should_not be_empty
    end
  end

  it "should correctly return shards for all blocks defined in the mapping table" do
    blocks = @conn.select_all("SELECT * FROM event_shards_map")

    blocks.each do |blk|
      shard = @sharder.shard_for_key(blk['start_id'])
      shard[:connection_name].should match(/social.*#{blk['shard_id']}$/)

      shard = @sharder.shard_for_key(blk['start_id'].to_i + 1)
      shard[:connection_name].should match(/social.*#{blk['shard_id']}$/)

      shard = @sharder.shard_for_key(blk['end_id'].to_i - 1)
      shard[:connection_name].should match(/social.*#{blk['shard_id']}$/)
    end
  end

  describe "for non-existing blocks" do
    before do
      @max_id = @conn.select_value("SELECT max(end_id) FROM event_shards_map").to_i
      Rails.cache.clear
    end

    it "should not fail" do
      lambda {
         @sharder.shard_for_key(@max_id + 1)
      }.should_not raise_error
    end

    it "should create a new one" do
      @sharder.shard_for_key(@max_id + 1).should_not be_nil
    end

    it "should assign it to the least loaded shard" do
      @sharder.shard_for_key(@max_id + 1)[:connection_name].should match(/shard.*03$/)
    end

    it "should not consider non-open shards" do
      @conn.execute("UPDATE event_shards_info SET open = 0 WHERE id = 3")
      @sharder.shard_for_key(@max_id + 1)[:connection_name].should_not match(/shard.*03$/)
    end

    it "should not consider disabled shards" do
      @conn.execute("UPDATE event_shards_info SET enabled = 0 WHERE id = 3")
      @sharder.shard_for_key(@max_id + 1)[:connection_name].should_not match(/shard.*03$/)
    end

    it "should increment the blocks counter on the shard" do
      lambda {
        @sharder.shard_for_key(@max_id + 1)
      }.should change {
         @conn.select_value("SELECT blocks_count FROM event_shards_info WHERE id = 3").to_i
      }.by(+1)
    end

    it "should raise duplicate key error when allocating same block twice" do
      @sharder.allocate_new_block_for_key(@max_id + 1)
      lambda {
        @sharder.allocate_new_block_for_key(@max_id + 1)
      }.should raise_error(ActiveRecord::StatementInvalid)
    end

    it "should handle duplicate key errors" do
      @sharder.shard_for_key(@max_id + 1)

      actual_block = @sharder.block_for_key(@max_id + 1)
      @sharder.should_receive(:block_for_key).twice.and_return(nil, actual_block)

      @sharder.shard_for_key(@max_id + 1)
    end
  end

  it "should fail on invalid shard references" do
     @conn.execute("DELETE FROM event_shards_info")
     lambda { @sharder.shard_for_key(1) }.should raise_error(ArgumentError)
  end

  it "should cache shards info" do
    shard = DbCharmer::Sharding::Method::DbBlockMap::ShardInfo.first
    DbCharmer::Sharding::Method::DbBlockMap::ShardInfo.should_receive(:find_by_id).once.and_return(shard)
    @sharder.shard_info_by_id(1)
    @sharder.shard_info_by_id(1)
  end

  it "should not cache shards info when explicitly asked not to" do
    shard = DbCharmer::Sharding::Method::DbBlockMap::ShardInfo.first
    DbCharmer::Sharding::Method::DbBlockMap::ShardInfo.should_receive(:find_by_id).twice.and_return(shard)
    @sharder.shard_info_by_id(1, false)
    @sharder.shard_info_by_id(1, false)
  end

  it "should cache blocks" do
    @sharder.block_for_key(1)
    @sharder.connection.should_not_receive(:select_one)
    @sharder.block_for_key(1)
    @sharder.block_for_key(2)
  end

  it "should not cache blocks if asked not to" do
    block = @sharder.block_for_key(1)
    @sharder.connection.should_receive(:select_one).twice.and_return(block)
    @sharder.block_for_key(1, false)
    @sharder.block_for_key(2, false)
  end


end

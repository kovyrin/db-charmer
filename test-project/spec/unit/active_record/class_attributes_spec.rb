require 'spec_helper'

class FooModel < ActiveRecord::Base; end

describe DbCharmer, "for ActiveRecord models" do
  context "in db_charmer_connection_proxy methods" do
    before do
      FooModel.db_charmer_connection_proxy = nil
    end

    it "should implement both accessor methods" do
      proxy = mock('connection proxy')
      FooModel.db_charmer_connection_proxy = proxy
      FooModel.db_charmer_connection_proxy.should be(proxy)
    end
  end

  context "in db_charmer_default_connection methods" do
    before do
      FooModel.db_charmer_default_connection = nil
    end

    it "should implement both accessor methods" do
      conn = mock('connection')
      FooModel.db_charmer_default_connection = conn
      FooModel.db_charmer_default_connection.should be(conn)
    end
  end

  context "in db_charmer_opts methods" do
    before do
      FooModel.db_charmer_opts = nil
    end

    it "should implement both accessor methods" do
      opts = { :foo => :bar}
      FooModel.db_charmer_opts = opts
      FooModel.db_charmer_opts.should be(opts)
    end
  end

  context "in db_charmer_slaves methods" do
    it "should return [] if no slaves set for a model" do
      FooModel.db_charmer_slaves = nil
      FooModel.db_charmer_slaves.should == []
    end

    it "should implement both accessor methods" do
      proxy = mock('connection proxy')
      FooModel.db_charmer_slaves = [ proxy ]
      FooModel.db_charmer_slaves.should == [ proxy ]
    end

    it "should implement random slave selection" do
      FooModel.db_charmer_slaves = [ :proxy1, :proxy2, :proxy3 ]
      srand(0)
      FooModel.db_charmer_random_slave.should == :proxy1
      FooModel.db_charmer_random_slave.should == :proxy2
      FooModel.db_charmer_random_slave.should == :proxy1
      FooModel.db_charmer_random_slave.should == :proxy2
      FooModel.db_charmer_random_slave.should == :proxy2
      FooModel.db_charmer_random_slave.should == :proxy3
    end
  end

  context "in db_charmer_connection_levels methods" do
    it "should return 0 by default" do
      FooModel.db_charmer_connection_level = nil
      FooModel.db_charmer_connection_level.should == 0
    end

    it "should implement both accessor methods and support inc/dec operations" do
      FooModel.db_charmer_connection_level = 1
      FooModel.db_charmer_connection_level.should == 1
      FooModel.db_charmer_connection_level += 1
      FooModel.db_charmer_connection_level.should == 2
      FooModel.db_charmer_connection_level -= 1
      FooModel.db_charmer_connection_level.should == 1
    end

    it "should implement db_charmer_top_level_connection? method" do
      FooModel.db_charmer_connection_level = 1
      FooModel.should_not be_db_charmer_top_level_connection
      FooModel.db_charmer_connection_level = 0
      FooModel.should be_db_charmer_top_level_connection
    end
  end

  context "in connection method" do
    it "should return AR's original connection if no connection proxy is set" do
      FooModel.db_charmer_connection_proxy = nil
      FooModel.connection.should be_kind_of(ActiveRecord::ConnectionAdapters::AbstractAdapter)
    end
  end

  context "in db_charmer_force_slave_reads? method" do
    it "should use per-model settings when possible" do
      FooModel.db_charmer_force_slave_reads = true
      DbCharmer.should_not_receive(:force_slave_reads?)
      FooModel.db_charmer_force_slave_reads?.should be_true
    end

    it "should use global settings when local setting is false" do
      FooModel.db_charmer_force_slave_reads = false

      DbCharmer.should_receive(:force_slave_reads?).and_return(true)
      FooModel.db_charmer_force_slave_reads?.should be_true

      DbCharmer.should_receive(:force_slave_reads?).and_return(false)
      FooModel.db_charmer_force_slave_reads?.should be_false
    end
  end
end

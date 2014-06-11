require 'spec_helper'

class Blah < ActiveRecord::Base; end

describe "In ActiveRecord models" do
  describe "db_magic method" do
    context "with :connection parameter" do
      after do
        DbCharmer.connections_should_exist = false
      end

      it "should change model's connection to specified one" do
        Blah.db_magic :connection => :logs
        Blah.connection.object_id.should == DbCharmer::ConnectionFactory.connect(:logs).object_id
      end

      it "should pass :should_exist paramater value to the underlying connection logic" do
        DbCharmer::ConnectionFactory.should_receive(:connect).with(:logs, 'blah')
        Blah.db_magic :connection => :logs, :should_exist => 'blah'
        DbCharmer.connections_should_exist = true
        DbCharmer::ConnectionFactory.should_receive(:connect).with(:logs, false)
        Blah.db_magic :connection => :logs, :should_exist => false
      end

      it "should use global DbCharmer's connections_should_exist attribute if no :should_exist passed" do
        DbCharmer.connections_should_exist = true
        DbCharmer::ConnectionFactory.should_receive(:connect).with(:logs, true)
        Blah.db_magic :connection => :logs
      end
    end

    context "with :slave or :slaves parameter" do
      it "should merge :slave and :slaves values" do
        Blah.db_charmer_slaves = []
        Blah.db_charmer_slaves.should be_empty

        Blah.db_magic :slave => :slave01
        Blah.db_charmer_slaves.size.should == 1

        Blah.db_magic :slaves => [ :slave01 ]
        Blah.db_charmer_slaves.size.should == 1

        Blah.db_magic :slaves => [ :slave01 ], :slave => :logs
        Blah.db_charmer_slaves.size.should == 2
      end

      it "should make db_charmer_force_slave_reads = true by default" do
        Blah.db_magic :slave => :slave01
        Blah.db_charmer_force_slave_reads.should be(true)
      end

      it "should pass force_slave_reads value to db_charmer_force_slave_reads" do
        Blah.db_magic :slave => :slave01, :force_slave_reads => false
        Blah.db_charmer_force_slave_reads.should be(false)

        Blah.db_magic :slave => :slave01, :force_slave_reads => true
        Blah.db_charmer_force_slave_reads.should be(true)
      end
    end

    it "should set up a hook to propagate db_magic params to all the children models" do
      class ParentFoo < ActiveRecord::Base
        db_magic :foo => :bar
      end
      class ChildFoo < ParentFoo; end

      ChildFoo.db_charmer_opts.should == ParentFoo.db_charmer_opts
    end

    context "with :sharded parameter" do
      class ShardTestingFoo < ActiveRecord::Base
        db_magic :sharded => { :key => :id, :sharded_connection => :texts }
      end

      it "should add shard_for method to the model" do
        ShardTestingFoo.should respond_to(:shard_for)
      end
    end
  end
end

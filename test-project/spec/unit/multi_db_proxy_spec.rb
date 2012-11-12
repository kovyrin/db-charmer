require 'spec_helper'

describe "ActiveRecord model with db_magic" do
  before do
    class Blah < ActiveRecord::Base
      self.table_name = :posts
      db_magic :connection => nil
    end
  end

  describe "(instance)" do
    before do
      @blah = Blah.new
    end

    describe "in on_db method" do
      describe "with a block" do
        it "should switch connection to specified one and yield the block" do
          Blah.db_charmer_connection_proxy.should be_nil
          @blah.on_db(:logs) do
            Blah.db_charmer_connection_proxy.should_not be_nil
          end
        end

        it "should switch connection back after the block finished its work" do
          Blah.db_charmer_connection_proxy.should be_nil
          @blah.on_db(:logs) {}
          Blah.db_charmer_connection_proxy.should be_nil
        end

        it "should manage connection level values" do
          Blah.db_charmer_connection_level.should == 0
          @blah.on_db(:logs) do |m|
            m.class.db_charmer_connection_level.should == 1
          end
          Blah.db_charmer_connection_level.should == 0
        end
      end

      describe "as a chain call" do
        it "should switch connection for all chained calls" do
          Blah.db_charmer_connection_proxy.should be_nil
          @blah.on_db(:logs).should_not be_nil
        end

        it "should switch connection for non-chained calls" do
          Blah.db_charmer_connection_proxy.should be_nil
          @blah.on_db(:logs).to_s
          Blah.db_charmer_connection_proxy.should be_nil
        end
      end
    end
  end

  describe "(class)" do
    describe "in on_db method" do
      describe "with a block" do
        it "should switch connection to specified one and yield the block" do
          Blah.db_charmer_connection_proxy.should be_nil
          Blah.on_db(:logs) do
            Blah.db_charmer_connection_proxy.should_not be_nil
          end
        end

        it "should switch connection back after the block finished its work" do
          Blah.db_charmer_connection_proxy.should be_nil
          Blah.on_db(:logs) {}
          Blah.db_charmer_connection_proxy.should be_nil
        end

        it "should manage connection level values" do
          Blah.db_charmer_connection_level.should == 0
          Blah.on_db(:logs) do |m|
            m.db_charmer_connection_level.should == 1
          end
          Blah.db_charmer_connection_level.should == 0
        end
      end

      describe "as a chain call" do
        it "should switch connection for all chained calls" do
          Blah.db_charmer_connection_proxy.should be_nil
          Blah.on_db(:logs).should_not be_nil
        end

        it "should switch connection for non-chained calls" do
          Blah.db_charmer_connection_proxy.should be_nil
          Blah.on_db(:logs).to_s
          Blah.db_charmer_connection_proxy.should be_nil
        end
      end
    end

    describe "in on_slave method" do
      before do
        Blah.db_magic :slaves => [ :slave01 ]
      end

      it "should use one tof the model's slaves if no slave given" do
        Blah.on_slave.db_charmer_connection_proxy.object_id.should == Blah.coerce_to_connection_proxy(:slave01).object_id
      end

      it "should use given slave" do
        Blah.on_slave(:logs).db_charmer_connection_proxy.object_id.should == Blah.coerce_to_connection_proxy(:logs).object_id
      end

      it 'should support block calls' do
        Blah.on_slave do |m|
          m.db_charmer_connection_proxy.object_id.should == Blah.coerce_to_connection_proxy(:slave01).object_id
        end
      end
    end

    describe "in on_master method" do
      before do
        Blah.db_magic :slaves => [ :slave01 ]
      end

      it "should run queries on the master" do
        Blah.on_master.db_charmer_connection_proxy.should be_nil
      end
    end
  end
end

require 'spec_helper'

describe "ActiveRecord slave-enabled models" do
  before do
    class User < ActiveRecord::Base
      db_magic :connection => :user_master, :slave => :slave01
    end
  end

  describe "in finder method" do
    [ :last, :first, :all ].each do |meth|
      describe meth do
        it "should go to the slave if called on the first level connection" do
          User.on_slave.connection.should_receive(:select_all).and_return([])
          User.send(meth)
        end

        it "should not change connection if called in an on_db block" do
          stub_columns_for_rails31 User.on_db(:logs).connection
          User.on_db(:logs).connection.should_receive(:select_all).and_return([])
          User.on_slave.connection.should_not_receive(:select_all)
          User.on_db(:logs).send(meth)
        end

        it "should not change connection when it's already been changed by on_slave call" do
          pending "rails3: not sure if we need this spec" if DbCharmer.rails3?
          User.on_slave do
            User.on_slave.connection.should_receive(:select_all).and_return([])
            User.should_not_receive(:on_db)
            User.send(meth)
          end
        end

        it "should not change connection if called in a transaction" do
          User.on_db(:user_master).connection.should_receive(:select_all).and_return([])
          User.on_slave.connection.should_not_receive(:select_all)
          User.transaction { User.send(meth) }
        end
      end
    end

    it "should go to the master if called find with :lock => true option" do
      User.on_db(:user_master).connection.should_receive(:select_all).and_return([])
      User.on_slave.connection.should_not_receive(:select_all)
      User.find(:first, :lock => true)
    end

    it "should not go to the master if no :lock => true option passed" do
      User.on_db(:user_master).connection.should_not_receive(:select_all)
      User.on_slave.connection.should_receive(:select_all).and_return([])
      User.find(:first)
    end

    it "should correctly pass all find params to the underlying code" do
      User.delete_all
      u1 = User.create(:login => 'foo')
      u2 = User.create(:login => 'bar')

      User.find(:all, :conditions => { :login => 'foo' }).should == [ u1 ]
      User.find(:all, :limit => 1).size.should == 1
      User.find(:first, :conditions => { :login => 'bar' }).should == u2
    end
  end

  describe "in calculation method" do
    [ :count, :minimum, :maximum, :average ].each do |meth|
      describe meth do
        it "should go to the slave if called on the first level connection" do
          User.on_slave.connection.should_receive(:select_value).and_return(1)
          User.send(meth, :id).should == 1
        end

        it "should not change connection if called in an on_db block" do
          User.on_db(:logs).connection.should_receive(:select_value).and_return(1)
          User.on_slave.connection.should_not_receive(:select_value)
          User.on_db(:logs).send(meth, :id).should == 1
        end

        it "should not change connection when it's already been changed by an on_slave call" do
          pending "rails3: not sure if we need this spec" if DbCharmer.rails3?
          User.on_slave do
            User.on_slave.connection.should_receive(:select_value).and_return(1)
            User.should_not_receive(:on_db)
            User.send(meth, :id).should == 1
          end
        end

        it "should not change connection if called in a transaction" do
          User.on_db(:user_master).connection.should_receive(:select_value).and_return(1)
          User.on_slave.connection.should_not_receive(:select_value)
          User.transaction { User.send(meth, :id).should == 1 }
        end
      end
    end
  end

  describe "in data manipulation methods" do
    it "should go to the master by default" do
      User.on_db(:user_master).connection.should_receive(:delete)
      User.delete_all
    end

    it "should go to the master even in slave-enabling chain calls" do
      User.on_db(:user_master).connection.should_receive(:delete)
      User.on_slave.delete_all
    end

    it "should go to the master even in slave-enabling block calls" do
      User.on_db(:user_master).connection.should_receive(:delete)
      User.on_slave { |u| u.delete_all }
    end
  end

  describe "in instance method" do
    describe "reload" do
      it "should always be done on the master" do
        User.delete_all
        u = User.create

        User.on_db(:user_master).connection.should_receive(:select_all).and_return([{}])
        User.on_slave.connection.should_not_receive(:select_all)

        User.on_slave { u.reload }
      end
    end
  end
end

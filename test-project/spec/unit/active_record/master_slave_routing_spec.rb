require 'spec_helper'

describe "ActiveRecord slave-enabled models" do
  before do
    class User < ActiveRecord::Base
      db_magic :connection => :user_master, :slave => :slave01
    end
  end

  def proxy_select_to_master(model, method = :select_all)
    model.connection.should_receive(method) do |*args|
      User.on_master.connection.send(method, *args)
    end
  end

  def select_value_method
    if DbCharmer.rails4?
      :select_all
    else
      :select_value
    end
  end

  #-------------------------------------------------------------------------------------------------
  describe "in finder method" do
    [ :last, :first, :all ].each do |meth|
      describe meth do
        it "should go to the slave if called on the first level connection" do
          proxy_select_to_master(User.on_slave)
          User.send(meth).inspect # to force arel to touch the database
        end

        it "should not change connection if called in an on_db block" do
          stub_columns_for_rails31 User.on_db(:logs).connection
          proxy_select_to_master(User.on_db(:logs))
          User.on_slave.connection.should_not_receive(:select_all)
          User.on_db(:logs).send(meth).inspect # to force arel to touch the database
        end

        it "should not change connection if called in a transaction" do
          User.on_db(:user_master).connection.should_receive(:select_all).and_call_original
          User.on_slave.connection.should_not_receive(:select_all)
          User.transaction do
            User.send(meth).inspect # to force arel to touch the database
          end
        end
      end
    end

    it "should go to the master if called find with :lock => true option" do
      User.on_db(:user_master).connection.should_receive(:select_all).and_call_original
      User.on_slave.connection.should_not_receive(:select_all)
      User.find(:first, :lock => true)
    end

    it "should not go to the master if no :lock => true option passed" do
      User.on_db(:user_master).connection.should_not_receive(:select_all)
      User.on_slave.connection.should_receive(:select_all).and_call_original
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
    # Prepare the database so that all of of our calculations would return 1
    before do
      User.delete_all
      u = User.new
      u.id = 1
      u.save!
    end

    [ :count, :minimum, :maximum, :average ].each do |meth|
      describe meth do
        it "should go to the slave if called on the first level connection" do
          proxy_select_to_master(User.on_slave, select_value_method)
          User.send(meth, :id).should == 1
        end

        it "should not change connection if called in an on_db block" do
          proxy_select_to_master(User.on_db(:logs), select_value_method)
          User.on_slave.connection.should_not_receive(select_value_method)
          User.on_db(:logs).send(meth, :id).should == 1
        end

        it "should not change connection if called in a transaction" do
          User.on_db(:user_master).connection.should_receive(select_value_method).and_call_original
          User.on_slave.connection.should_not_receive(select_value_method)
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

        User.on_slave.connection.should_not_receive(:select_all)

        User.on_slave { u.reload }
      end
    end
  end
end

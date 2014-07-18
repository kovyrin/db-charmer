require 'spec_helper'

describe "ActiveRecord slave-enabled models" do
  class UserWithSlave < ActiveRecord::Base
    attr_accessible :login
    self.table_name = :users
    db_magic :connection => :user_master, :slave => :slave01
  end

  def proxy_select_to_master(model, method = :select_all)
    model.connection.should_receive(method) do |*args|
      UserWithSlave.on_master.connection.send(method, *args)
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
          proxy_select_to_master(UserWithSlave.on_slave)
          UserWithSlave.send(meth).inspect # to force arel to touch the database
        end

        it "should not change connection if called in an on_db block" do
          stub_columns_for_rails31 UserWithSlave.on_db(:logs).connection
          proxy_select_to_master(UserWithSlave.on_db(:logs))
          UserWithSlave.on_slave.connection.should_not_receive(:select_all)
          UserWithSlave.on_db(:logs).send(meth).inspect # to force arel to touch the database
        end

        it "should not change connection if called in a transaction" do
          UserWithSlave.on_db(:user_master).connection.should_receive(:select_all).and_call_original
          UserWithSlave.on_slave.connection.should_not_receive(:select_all)
          UserWithSlave.transaction do
            UserWithSlave.send(meth).inspect # to force arel to touch the database
          end
        end
      end
    end

    it "should go to the master if called find with :lock => true option" do
      UserWithSlave.on_db(:user_master).connection.should_receive(:select_all).and_call_original
      UserWithSlave.on_slave.connection.should_not_receive(:select_all)
      UserWithSlave.lock(true).first
    end

    it "should not go to the master if no :lock => true option passed" do
      UserWithSlave.on_db(:user_master).connection.should_not_receive(:select_all)
      UserWithSlave.on_slave.connection.should_receive(:select_all).and_call_original
      UserWithSlave.first
    end

    it "should correctly pass all find params to the underlying code" do
      UserWithSlave.delete_all
      u1 = UserWithSlave.create(:login => 'foo')
      u2 = UserWithSlave.create(:login => 'bar')

      UserWithSlave.where(:login => 'foo').should == [ u1 ]
      limited_set = DbCharmer.rails31? ? UserWithSlave.limit(1) : UserWithSlave.find(:all, :limit => 1)
      limited_set.size.should == 1
      UserWithSlave.where(:login => 'bar').first.should == u2
    end
  end

  describe "in calculation method" do
    # Prepare the database so that all of of our calculations would return 1
    before do
      UserWithSlave.delete_all
      u = UserWithSlave.new
      u.id = 1
      u.save!
    end

    [ :count, :minimum, :maximum, :average ].each do |meth|
      describe meth do
        it "should go to the slave if called on the first level connection" do
          proxy_select_to_master(UserWithSlave.on_slave, select_value_method)
          UserWithSlave.send(meth, :id).should == 1
        end

        it "should not change connection if called in an on_db block" do
          proxy_select_to_master(UserWithSlave.on_db(:logs), select_value_method)
          UserWithSlave.on_slave.connection.should_not_receive(select_value_method)
          UserWithSlave.on_db(:logs).send(meth, :id).should == 1
        end

        it "should not change connection if called in a transaction" do
          UserWithSlave.on_db(:user_master).connection.should_receive(select_value_method).and_call_original
          UserWithSlave.on_slave.connection.should_not_receive(select_value_method)
          UserWithSlave.transaction { UserWithSlave.send(meth, :id).should == 1 }
        end
      end
    end
  end

  describe "in data manipulation methods" do
    it "should go to the master by default" do
      UserWithSlave.on_db(:user_master).connection.should_receive(:delete)
      UserWithSlave.delete_all
    end

    it "should go to the master even in slave-enabling chain calls" do
      UserWithSlave.on_db(:user_master).connection.should_receive(:delete)
      UserWithSlave.on_slave.delete_all
    end

    it "should go to the master even in slave-enabling block calls" do
      UserWithSlave.on_db(:user_master).connection.should_receive(:delete)
      UserWithSlave.on_slave { |u| u.delete_all }
    end
  end

  describe "in instance method" do
    describe "reload" do
      it "should always be done on the master" do
        UserWithSlave.delete_all
        u = UserWithSlave.create

        UserWithSlave.on_slave.connection.should_not_receive(:select_all)

        UserWithSlave.on_slave { u.reload }
      end
    end
  end
end

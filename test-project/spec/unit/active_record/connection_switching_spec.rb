require 'spec_helper'

class FooModel < ActiveRecord::Base; end
class BarModel < ActiveRecord::Base; end

describe DbCharmer, "AR connection switching" do
  describe "in switch_connection_to method" do
    before(:all) do
      BarModel.hijack_connection!
    end

    before :each do
      @proxy = mock('proxy')
      @proxy.stub!(:db_charmer_connection_name).and_return(:myproxy)
    end

    before do
      BarModel.db_charmer_connection_proxy = @proxy
      BarModel.connection.should be(@proxy)
    end

    it "should accept nil and reset connection to default" do
      BarModel.switch_connection_to(nil)
      BarModel.connection.should be(ActiveRecord::Base.connection)
    end

    it "should accept a string and generate an abstract class with connection factory" do
      BarModel.switch_connection_to('logs')
      BarModel.connection.object_id == DbCharmer::ConnectionFactory.connect('logs').object_id
    end

    it "should accept a symbol and generate an abstract class with connection factory" do
      BarModel.switch_connection_to(:logs)
      BarModel.connection.object_id.should == DbCharmer::ConnectionFactory.connect('logs').object_id
    end

    it "should accept a model and use its connection proxy value" do
      FooModel.switch_connection_to(:logs)
      BarModel.switch_connection_to(FooModel)
      BarModel.connection.object_id.should == DbCharmer::ConnectionFactory.connect('logs').object_id
    end

    context "with a hash parameter" do
      before do
        @conf = {
          :adapter => 'mysql',
          :username => "db_charmer_ro",
          :database => "db_charmer_sandbox_test",
          :connection_name => 'sanbox_ro'
        }
      end

      it "should fail if there is no :connection_name parameter" do
        @conf.delete(:connection_name)
        lambda { BarModel.switch_connection_to(@conf) }.should raise_error(ArgumentError)
      end

      it "generate an abstract class with connection factory" do
        BarModel.switch_connection_to(@conf)
        BarModel.connection.object_id.should == DbCharmer::ConnectionFactory.connect_to_db(@conf[:connection_name], @conf).object_id
      end
    end

    it "should support connection switching for AR::Base" do
      ActiveRecord::Base.switch_connection_to(:logs)
      ActiveRecord::Base.connection.object_id == DbCharmer::ConnectionFactory.connect('logs').object_id
      ActiveRecord::Base.switch_connection_to(nil)
    end
  end
end

describe DbCharmer, "for ActiveRecord models" do
  describe "in establish_real_connection_if_exists method" do
    it "should check connection name if requested" do
      lambda { FooModel.establish_real_connection_if_exists(:foo, true) }.should raise_error(ArgumentError)
    end

    it "should not check connection name if not reqested" do
      lambda { FooModel.establish_real_connection_if_exists(:foo) }.should_not raise_error
    end

    it "should not check connection name if reqested not to" do
      lambda { FooModel.establish_real_connection_if_exists(:foo, false) }.should_not raise_error
    end

    it "should establish connection when connection configuration exists" do
      FooModel.should_receive(:establish_connection)
      FooModel.establish_real_connection_if_exists(:logs)
    end

    it "should not establish connection even when connection configuration does not exist" do
      FooModel.should_not_receive(:establish_connection)
      FooModel.establish_real_connection_if_exists(:blah)
    end
  end
end

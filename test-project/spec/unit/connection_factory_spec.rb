require 'spec_helper'

describe DbCharmer::ConnectionFactory do
  context "in generate_abstract_class method" do
    it "should fail if requested connection config does not exists" do
      lambda { DbCharmer::ConnectionFactory.generate_abstract_class('foo') }.should raise_error(ArgumentError)
    end

    it "should not fail if requested connection config does not exists and should_exist = false" do
      lambda { DbCharmer::ConnectionFactory.generate_abstract_class('foo', false) }.should_not raise_error
    end

    it "should fail if requested connection config does not exists and should_exist = true" do
      lambda { DbCharmer::ConnectionFactory.generate_abstract_class('foo', true) }.should raise_error(ArgumentError)
    end

    it "should generate abstract connection classes" do
      klass = DbCharmer::ConnectionFactory.generate_abstract_class('foo', false)
      klass.superclass.should be(ActiveRecord::Base)
    end

    it "should work with weird connection names" do
      klass = DbCharmer::ConnectionFactory.generate_abstract_class('foo.bar@baz#blah', false)
      klass.superclass.should be(ActiveRecord::Base)
    end
  end

  context "in generate_empty_abstract_ar_class method" do
    it "should generate an abstract connection class" do
      klass = DbCharmer::ConnectionFactory.generate_empty_abstract_ar_class('::MyFooAbstractClass')
      klass.superclass.should be(ActiveRecord::Base)
    end
  end

  context "in establish_connection method" do
    it "should generate an abstract class" do
      klass = mock('AbstractClass')
      conn = mock('connection1')
      klass.stub!(:retrieve_connection).and_return(conn)
      DbCharmer::ConnectionFactory.should_receive(:generate_abstract_class).and_return(klass)
      DbCharmer::ConnectionFactory.establish_connection(:foo).should be(conn)
    end

    it "should create and return a connection proxy for the abstract class" do
      klass = mock('AbstractClass')
      DbCharmer::ConnectionFactory.should_receive(:generate_abstract_class).and_return(klass)
      DbCharmer::ConnectionProxy.should_receive(:new).with(klass, :foo)
      DbCharmer::ConnectionFactory.establish_connection(:foo)
    end
  end

  context "in establish_connection_to_db method" do
    it "should generate an abstract class" do
      klass = mock('AbstractClass')
      conn =  mock('connection2')
      klass.stub!(:establish_connection)
      klass.stub!(:retrieve_connection).and_return(conn)
      DbCharmer::ConnectionFactory.should_receive(:generate_empty_abstract_ar_class).and_return(klass)
      DbCharmer::ConnectionFactory.establish_connection_to_db(:foo, :username => :foo).should be(conn)
    end

    it "should create and return a connection proxy for the abstract class" do
      klass = mock('AbstractClass')
      klass.stub!(:establish_connection)
      DbCharmer::ConnectionFactory.should_receive(:generate_empty_abstract_ar_class).and_return(klass)
      DbCharmer::ConnectionProxy.should_receive(:new).with(klass, :foo)
      DbCharmer::ConnectionFactory.establish_connection_to_db(:foo, :username => :foo)
    end
  end

  context "in connect method" do
    before do
      DbCharmer::ConnectionFactory.reset!
    end

    it "should return a connection proxy" do
      DbCharmer::ConnectionFactory.connect(:logs).should be_kind_of(ActiveRecord::ConnectionAdapters::AbstractAdapter)
    end

# should_receive is evil on a singletone classes
#    it "should memoize proxies" do
#      conn = mock('connection3')
#      DbCharmer::ConnectionFactory.should_receive(:establish_connection).with('foo', false).once.and_return(conn)
#      DbCharmer::ConnectionFactory.connect(:foo)
#      DbCharmer::ConnectionFactory.connect(:foo)
#    end
  end

  context "in connect_to_db method" do
    before do
      DbCharmer::ConnectionFactory.reset!
      @conf = ActiveRecord::Base.configurations['common'].merge(
        :username => "db_charmer_ro",
        :database => "db_charmer_sandbox_test",
        :connection_name => 'sanbox_ro'
      )
    end

    it "should return a connection proxy" do
      DbCharmer::ConnectionFactory.connect_to_db(@conf[:connection_name], @conf).should be_kind_of(ActiveRecord::ConnectionAdapters::AbstractAdapter)
    end

# should_receive is evil on a singletone classes
#    it "should memoize proxies" do
#      conn = mock('connection4')
#      DbCharmer::ConnectionFactory.should_receive(:establish_connection_to_db).with(@conf[:connection_name], @conf).once.and_return(conn)
#      DbCharmer::ConnectionFactory.connect_to_db(@conf[:connection_name], @conf)
#      DbCharmer::ConnectionFactory.connect_to_db(@conf[:connection_name], @conf)
#    end
  end

end

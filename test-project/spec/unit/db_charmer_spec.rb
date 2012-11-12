require 'spec_helper'

describe DbCharmer do
  after do
    DbCharmer.current_controller = nil
    DbCharmer.connections_should_exist = false
  end

  it "should define version constants" do
    DbCharmer::Version::STRING.should match(/^\d+\.\d+\.\d+/)
  end

  it "should have connections_should_exist accessors" do
    DbCharmer.connections_should_exist.should_not be_nil
    DbCharmer.connections_should_exist = :foo
    DbCharmer.connections_should_exist.should == :foo
  end

  it "should have connections_should_exist? method" do
    DbCharmer.connections_should_exist = true
    DbCharmer.connections_should_exist?.should be_true
    DbCharmer.connections_should_exist = false
    DbCharmer.connections_should_exist?.should be_false
    DbCharmer.connections_should_exist = "shit"
    DbCharmer.connections_should_exist?.should be_true
    DbCharmer.connections_should_exist = nil
    DbCharmer.connections_should_exist?.should be_false
  end

  it "should have current_controller accessors" do
    DbCharmer.respond_to?(:current_controller).should be_true
    DbCharmer.current_controller = :foo
    DbCharmer.current_controller.should == :foo
    DbCharmer.current_controller = nil
  end

  context "in force_slave_reads? method" do
    it "should return true if force_slave_reads=true" do
      DbCharmer.force_slave_reads?.should be_false

      DbCharmer.force_slave_reads do
        DbCharmer.force_slave_reads?.should be_true
      end

      DbCharmer.force_slave_reads?.should be_false
    end

    it "should return false if no controller defined and global force_slave_reads=false" do
      DbCharmer.current_controller = nil
      DbCharmer.force_slave_reads?.should be_false
    end

    it "should consult with the controller about forcing slave reads if possible" do
      DbCharmer.current_controller = mock("controller")

      DbCharmer.current_controller.should_receive(:force_slave_reads?).and_return(true)
      DbCharmer.force_slave_reads?.should be_true

      DbCharmer.current_controller.should_receive(:force_slave_reads?).and_return(false)
      DbCharmer.force_slave_reads?.should be_false
    end
  end

  context "in with_controller method" do
    it "should fail if no block given" do
      lambda { DbCharmer.with_controller(:foo) }.should raise_error(ArgumentError)
    end

    it "should switch controller while running the block" do
      DbCharmer.current_controller = nil
      DbCharmer.current_controller.should be_nil

      DbCharmer.with_controller(:foo) do
        DbCharmer.current_controller.should == :foo
      end

      DbCharmer.current_controller.should be_nil
    end

    it "should ensure current controller is reverted to nil in case of errors" do
      lambda {
        DbCharmer.with_controller(:foo) { raise "fuck" }
      }.should raise_error
      DbCharmer.current_controller.should be_nil
    end
  end
end

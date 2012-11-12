require 'spec_helper'

if DbCharmer.rails2?
  describe 'AbstractAdapter' do
    it "should respond to connection_name accessor" do
      ActiveRecord::Base.connection.respond_to?(:connection_name).should be_true
    end

    it "should have connection_name read accessor working" do
      DbCharmer::ConnectionFactory.generate_abstract_class('logs').connection.connection_name.should == 'logs'
      DbCharmer::ConnectionFactory.generate_abstract_class('slave01').connection.connection_name.should == 'slave01'
      ActiveRecord::Base.connection.connection_name.should be_nil
    end

    it "should append connection name to log records on non-default connections" do
      User.switch_connection_to nil
      default_message = User.connection.send(:format_log_entry, 'hello world')
      switched_message = User.on_db(:slave01).connection.send(:format_log_entry, 'hello world')
      switched_message.should_not == default_message
      switched_message.should match(/slave01/)
    end
  end
end

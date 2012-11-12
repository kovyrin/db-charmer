require 'spec_helper'

class BlahController < ActionController::Base; end

describe ActionController, "with force_slave_reads extension" do
  before do
    BlahController.force_slave_reads({}) # cleanup status
  end

  it "should not force slave reads when there are no actions defined as forced" do
    BlahController.force_slave_reads_action?(:index).should be_false
  end

  it "should force slave reads for :only actions" do
    BlahController.force_slave_reads :only => :index
    BlahController.force_slave_reads_action?(:index).should be_true
  end

  it "should not force slave reads for non-listed actions when there is :only parameter" do
    BlahController.force_slave_reads :only => :index
    BlahController.force_slave_reads_action?(:show).should be_false
  end

  it "should not force slave reads for :except actions" do
    BlahController.force_slave_reads :except => :delete
    BlahController.force_slave_reads_action?(:delete).should be_false
  end

  it "should force slave reads for non-listed actions when there is :except parameter" do
    BlahController.force_slave_reads :except => :delete
    BlahController.force_slave_reads_action?(:index).should be_true
  end

  it "should not force slave reads for actions listed in both :except and :only lists" do
    BlahController.force_slave_reads :only => :delete, :except => :delete
    BlahController.force_slave_reads_action?(:delete).should be_false
  end

  it "should not force slave reads for non-listed actions when there are :except and :only lists present" do
    BlahController.force_slave_reads :only => :index, :except => :delete
    BlahController.force_slave_reads_action?(:show).should be_false
  end
end

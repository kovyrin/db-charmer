require 'spec_helper'

describe PostsController do
  fixtures :posts

  def select_value_method
    if DbCharmer.rails4?
      :select_all
    else
      :select_value
    end
  end

  # Delete these examples and add some real ones
  it "should support db_charmer readonly actions method" do
    PostsController.respond_to?(:force_slave_reads).should be_true
  end

  it "index action should force slave reads" do
    PostsController.force_slave_reads_action?(:index).should be_true
  end

  it "create action should not force slave reads" do
    PostsController.force_slave_reads_action?(:create).should be_false
  end

  describe "GET 'index'" do
    context "slave reads enforcing (action is listed in :only)" do
      it "should enable enforcing" do
        get 'index'
        controller.force_slave_reads?.should be_true
      end

      it "should actually force slave reads" do
        Post.connection.should_not_receive(:select_value) # no counts
        Post.connection.should_not_receive(:select_all) # no finds
        Post.on_slave.connection.should_receive(select_value_method).and_call_original
        get 'index'
      end
    end
  end

  describe "GET 'show'" do
    context "slave reads enforcing (action is listed in :only)" do
      it "should enable enforcing" do
        get 'show', :id => Post.first.id
        controller.force_slave_reads?.should be_true
      end

      it "should actually force slave reads" do
        post = Post.first
        Post.connection.should_not_receive(:select_value) # no counts
        Post.connection.should_not_receive(:select_all) # no finds
        Post.on_slave.connection.should_receive(select_value_method).and_call_original
        Post.on_slave.connection.should_receive(:select_all).and_call_original
        get 'show', :id => post.id
      end
    end
  end

  describe "GET 'new'" do
    context "slave reads enforcing (action is listed in :except)" do
      it "should not enable enforcing" do
        get 'new'
        controller.force_slave_reads?.should be_false
      end

      it "should not do any actual enforcing" do
        Post.connection.should_receive(select_value_method).and_call_original
        Post.on_slave.connection.should_not_receive(:select_value) # no counts
        Post.on_slave.connection.should_not_receive(:select_all) # no selects
        get 'new'
      end
    end
  end

  describe "GET 'create'" do
    it "should redirect to post url upon successful completion" do
      get 'create', :post => { :title => 'xxx', :user_id => 1 }
      response.should redirect_to(post_url(Post.last))
    end

    it "should create a Post record" do
      lambda {
        get 'create', :post => { :title => 'xxx', :user_id => 1 }
      }.should change { Post.count }.by(+1)
    end

    context "slave reads enforcing (action is not listed in force_slave_reads params)" do
      it "should not enable enforcing" do
        get 'create'
        controller.force_slave_reads?.should_not be_true
      end

      it "should not do any actual enforcing" do
        Post.on_slave.connection.should_not_receive(:select_value)
        Post.connection.should_receive(select_value_method).once.and_call_original
        get 'create'
      end
    end
  end

  describe "GET 'destroy'" do
    it "should redurect to index upon completion" do
      get 'destroy', :id => Post.first.id
      response.should redirect_to(:action => :index)
    end

    it "should delete a record" do
      lambda {
        get 'destroy', :id => Post.first.id
      }.should change { Post.count }.by(-1)
    end
  end
end

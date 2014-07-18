require 'spec_helper'

describe "DbCharmer::AssociationProxy extending AR::Associations" do
  fixtures :users, :posts

  it "should add proxy? => true method" do
    users(:bill).posts.proxy?.should be(true)
  end

  describe "in has_many associations" do
    before do
      @user = users(:bill)
      @posts = @user.posts.to_a

      Post.switch_connection_to(:logs)
      User.switch_connection_to(:logs)

      # Make sure the next @user.posts call will touch the db again
      @user.clear_association_cache
    end

    after do
      Post.switch_connection_to(nil)
      User.switch_connection_to(nil)
    end

    it "should implement on_db proxy" do
      Post.connection.should_not_receive(:select_all)
      User.connection.should_not_receive(:select_all)

      stub_columns_for_rails31 Post.on_db(:logs).connection

      post_attributes = @posts.map { |p| p.attributes }
      slave_connection = Post.on_db(:slave01).connection
      slave_connection.should_receive(:select_all).and_return(post_attributes)

      on_db_proxy = @user.posts.on_db(:slave01)
      posts_from_on_db = on_db_proxy.to_a
      assert_equal @posts, posts_from_on_db
    end

    it "on_db should work in prefix mode" do
      Post.connection.should_not_receive(:select_all)
      User.connection.should_not_receive(:select_all)

      stub_columns_for_rails31 Post.on_db(:logs).connection
      post_attributes = @posts.map { |p| p.attributes }
      Post.on_db(:slave01).connection.should_receive(:select_all).and_return(post_attributes)
      @user.on_db(:slave01).posts.should == @posts
    end

    it "should actually proxy calls to the rails association proxy" do
      Post.switch_connection_to(nil)
      @user.posts.on_db(:slave01).count.should == @user.posts.count
    end

    it "should work with named scopes" do
      Post.switch_connection_to(nil)
      @user.posts.windows_posts.on_db(:slave01).count.should == @user.posts.windows_posts.count
    end

    it "should work with chained named scopes" do
      Post.switch_connection_to(nil)
      @user.posts.windows_posts.dummy_scope.on_db(:slave01).count.should == @user.posts.windows_posts.dummy_scope.count
    end
  end

  describe "in belongs_to associations" do
    before do
      @post = posts(:windoze)
      @user = users(:bill)
      User.switch_connection_to(:logs)
      User.connection.object_id.should_not == Post.connection.object_id
    end

    after do
      User.switch_connection_to(nil)
    end

    it "should implement on_db proxy" do
      skip
      Post.connection.should_not_receive(:select_all)
      User.connection.should_not_receive(:select_all)
      User.on_db(:slave01).connection.should_receive(:select_all).once.and_return([ @user ])
      @post.user.on_db(:slave01).should == @post.user
    end

    it "on_db should work in prefix mode" do
      skip
      Post.connection.should_not_receive(:select_all)
      User.connection.should_not_receive(:select_all)
      User.on_db(:slave01).connection.should_receive(:select_all).once.and_return([ @user ])
      @post.on_db(:slave01).user.should == @post.user
    end

    it "should actually proxy calls to the rails association proxy" do
      User.switch_connection_to(nil)
      @post.user.on_db(:slave01).should == @post.user
    end
  end
end

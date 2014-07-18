require 'spec_helper'

describe "ActiveRecord in finder methods" do
  fixtures :categories, :users, :posts, :categories_posts, :avatars

  before do
    Post.db_magic :connection => nil
    User.db_magic :connection => nil
  end

  after do
    Post.db_magic(Post::DB_MAGIC_DEFAULT_PARAMS)
  end

  it "should switch all belongs_to association connections when :include is used" do
    User.connection.should_not_receive(:select_all)
    Post.on_db(:slave01).includes(:user).to_a
  end

  it "should switch all has_many association connections when :include is used" do
    Post.connection.should_not_receive(:select_all)
    User.on_db(:slave01).includes(:posts).to_a
  end

  it "should switch all has_one association connections when :include is used" do
    Avatar.connection.should_not_receive(:select_all)
    User.on_db(:slave01).includes(:avatar).to_a
  end

  it "should switch all has_and_belongs_to_many association connections when :include is used" do
    Post.connection.should_not_receive(:select_all)
    Category.on_db(:slave01).includes(:posts).to_a
  end

  #-------------------------------------------------------------------------------------------
  it "should not switch assocations when called on a top-level connection" do
    User.connection.should_receive(:select_all).and_return([])
    Post.includes(:user).to_a
  end

  it "should not switch connection when association model and main model are on different servers" do
    LogRecord.connection.should_receive(:select_all).and_return([])
    User.on_db(:slave01).includes(:log_records).to_a
  end
end

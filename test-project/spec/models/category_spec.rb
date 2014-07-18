require 'spec_helper'

describe Category do
  before(:each) do
    @valid_attributes = {
      :name => "value for name"
    }
  end

  it "should create a new instance given valid attributes" do
    Category.create!(@valid_attributes)
  end

  context "issue #92" do
    fixtures :users, :categories, :categories_posts, :posts

    before do
      Category.switch_connection_to(nil)
      Post.switch_connection_to(nil)
    end

    it "should not happen" do
      # Get main db connection
      main_connection = Category.connection

      # Get slave connection and make sure it is different from the main one
      slave_connection = User.on_db(:slave01).connection
      main_connection.object_id.should_not == slave_connection.object_id

      # Get logs connection and make sure it is different from the main one
      logs_connection = User.on_db(:logs).connection
      main_connection.object_id.should_not == logs_connection.object_id

      # Proxy logs connection select calls to slave connection
      logs_connection.should_receive(:select_all).exactly(2).times do |*args|
        slave_connection.select_all(*args)
      end

      # Fine a category via a different connection
      cat = Category.on_db(:logs).find(1)

      # Find related posts for the category using a different connection
      cat.on_db(:logs).posts.to_a.should_not be_empty
    end
  end
end

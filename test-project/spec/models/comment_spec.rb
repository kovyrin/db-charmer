require 'spec_helper'

describe Comment do
  fixtures :comments, :avatars, :posts, :users

  describe "preload polymorphic association" do
    subject do
      lambda {
        Comment.find(:all, :include => :commentable)
      }
    end

    it { should_not raise_error }
  end
end

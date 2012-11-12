require 'spec_helper'

describe CategoriesPosts do
  before(:each) do
    @valid_attributes = {
      :post_id => 1,
      :category_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    CategoriesPosts.create!(@valid_attributes)
  end
end

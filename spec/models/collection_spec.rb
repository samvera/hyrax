require 'spec_helper'

describe Collection do
  before(:each) do
    @user = User.create(:login => "testuser", 
                        :email => "testuser@example.com", 
                        :password => "password", 
                        :password_confirmation => "password")
    @collection = Collection.create(:name => "test collection",
                                    :user_id => @user.id)
  end
  it "should belong to testuser" do
    @collection.user.should == @user
  end
  it "should be named 'test collection'" do
    @collection.name.should == "test collection"
  end
  it "should be accessible via user object" do
    @user.collections.count.should == 1
  end
end

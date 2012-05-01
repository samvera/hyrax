require 'spec_helper'

describe User do
  before do
    @user = User.create(:email => "testuser@example.com", 
                        :login => "testuser")
  end
  after do
    @user.delete
  end
  it "should have a login and email" do
    @user.login.should == "testuser"
    @user.email.should == "testuser@example.com"
  end
  
end

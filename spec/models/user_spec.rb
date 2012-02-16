require 'spec_helper'

describe User do
  before(:each) do
    @user = User.create(:login => "testuser", 
                        :email => "testuser@example.com", 
                        :password => "password", 
                        :password_confirmation => "password")
  end
  it "should have a login and email" do
    @user.login.should == "testuser@example.com"
    @user.email.should == "testuser@example.com"
  end
  it "should have zero folders by default" do
    Folder.find(:all, :query => {:creator => @user.email}).count.should == 0
  end
  it "should now have one folder" do
    f = Folder.create(:creator => @user.email)
    Folder.find(:all, :query => {:creator => @user.email}).count.should == 1
    f.delete
  end
end

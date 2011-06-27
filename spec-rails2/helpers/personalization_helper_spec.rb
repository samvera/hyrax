require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PersonalizationHelper do
  include PersonalizationHelper

  describe "accessing user attributes from user with no associated user_attributes" do
    before :each do
      @user = User.create(:login => "testuser", :email=> "testuser@example.com", :password => "password", :password_confirmation => "password")
    end

    it "should return empty strings for all user attributes" do
      full_name_from_login("testuser").should be_empty
      affiliation_from_login("testuser").should be_empty
      photo_from_login("testuser").should be_empty
      user_photo_tag("testusers").should be_empty
    end
  end

  describe "accessing user attributes from bundled active record associations" do
    before :each do
      @user = User.create(:login => "testuser", :email=> "testuser@example.com", :password => "password", :password_confirmation => "password")
      @ua = UserAttribute.create(:first_name => "Joe", :last_name => "Test",:affiliation => "Noplace Like Home", :photo => "/images/users/joe_test.jpg", :user_id => @user.id)
    end

    it "should return a full name" do
      full_name_from_login("testuser").should == "Joe Test"
    end

    it "should return an affiliation" do
      affiliation_from_login("testuser").should == "Noplace Like Home"
    end

    it "should return a path to a photo on the filesystem" do
      photo_from_login("testuser").should == "/images/users/joe_test.jpg"
    end

    it "should return an image tag for the photo" do
      generated_html = user_photo_tag("testuser")
      generated_html.should_not be_nil
      generated_html.should have_tag "img[src='/images/users/joe_test.jpg']"
    end
  end
end

require 'spec_helper'

describe "The Dashboard" do

  before do
    sign_in :user_with_fixtures
  end

  context "upon sign-in" do

    it "should show the user's information" do
      page.should have_content "My Dashboard"
      page.should have_content "User Activity"
      page.should have_content "User Notifications"
      page.should have_content "Your Statistics"
    end

    it "should let the user upload files" do
      click_link "Upload"
      page.should have_content "Upload"
    end

    it "should let the user create collections" do
      click_link "Create Collection"
      page.should have_content "Create New Collection"
    end

    it "should let the user view files" do
      click_link "View Files"
      page.should have_content "My Files"
      page.should have_content "My Collections"
      page.should have_content "My Highlights"
      page.should have_content "Files Shared with Me"
    end

  end

end

require 'spec_helper'

describe "The Dashboard", :type => :feature do

  before do
    sign_in :user_with_fixtures
  end

  context "upon sign-in" do

    it "should show the user's information" do
      expect(page).to have_content "My Dashboard"
      expect(page).to have_content "User Activity"
      expect(page).to have_content "User Notifications"
      expect(page).to have_content "Your Statistics"
    end

    it "should let the user upload files" do
      click_link "Upload"
      expect(page).to have_content "Upload"
    end

    it "should let the user create collections" do
      click_link "Create Collection"
      expect(page).to have_content "Create New Collection"
    end

    it "should let the user view files" do
      click_link "View Files"
      expect(page).to have_content "My Files"
      expect(page).to have_content "My Collections"
      expect(page).to have_content "My Highlights"
      expect(page).to have_content "Files Shared with Me"
    end

  end

end

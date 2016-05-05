require 'spec_helper'

describe "The Dashboard", type: :feature do
  before do
    sign_in :user_with_fixtures
  end

  context "upon sign-in" do
    it "shows the user's information" do
      expect(page).to have_content "My Dashboard"
      expect(page).to have_content "User Activity"
      expect(page).to have_content "User Notifications"
      expect(page).to have_content "Collections created"
      expect(page).to have_content "Works created"
    end

    it "lets the user create collections" do
      click_link "Create Collection"
      expect(page).to have_content "Create New Collection"
    end

    it "lets the user view works" do
      click_link "View Works"
      expect(page).to have_content "My Works"
      expect(page).to have_content "My Collections"
      expect(page).to have_content "My Highlights"
      expect(page).to have_content "Files Shared with Me"
    end
  end
end

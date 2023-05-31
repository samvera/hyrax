# frozen_string_literal: true
RSpec.describe "The dashboard as viewed by a regular user", type: :feature do
  before do
    sign_in
  end

  context "upon sign-in" do
    it "shows the user's information" do
      expect(page).to have_content "Dashboard"
      expect(page).to have_content "User Activity"
      expect(page).to have_content "User Notifications"

      # displays the breadcrumbs
      expect(page).to have_css '.breadcrumb'

      within '.sidebar' do
        expect(page).to have_link "Works"
        expect(page).to have_link "Collections"
      end
    end
  end
end

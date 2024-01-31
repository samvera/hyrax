# frozen_string_literal: true
RSpec.describe "The dashboard as viewed by a admin user", type: :feature do
  let(:admin) { create(:admin) }

  before do
    sign_in admin
  end

  context "upon sign-in" do
    it "shows the admin user's information" do
      expect(page).to have_content "Dashboard"
      expect(page).to have_content "Repository Growth"
      expect(page).to have_content "Visibility"
      expect(page).to have_content "Work Types"
      expect(page).to have_content "Resource Types"

      within '.sidebar' do
        expect(page).to have_link "Works"
        expect(page).to have_link "Collections"
        expect(page).to have_content "Review Submissions"
        expect(page).to have_content "Manage Embargoes"
        expect(page).to have_content "Manage Leases"
      end
    end
  end
end

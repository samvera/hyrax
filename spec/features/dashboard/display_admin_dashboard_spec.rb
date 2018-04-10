RSpec.describe "The dashboard as viewed by a admin user", type: :feature do
  before do
    sign_in create(:admin)
  end

  context "upon sign-in" do
    it "shows the admin user's information" do
      expect(page).to have_content "Dashboard"
      expect(page).to have_content "Registered Users"
      expect(page).to have_content "Visitors"
      expect(page).to have_content "Sessions"
      expect(page).to have_content "Administrative Sets"
      expect(page).to have_content "Recent activity"
      expect(page).to have_content "Administrative Set"
      expect(page).to have_content "User Activity"
      expect(page).to have_content "Repository Growth"
      expect(page).to have_content "Repository Objects"

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

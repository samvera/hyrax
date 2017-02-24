describe "The dashboard as viewed by a regular user", type: :feature do
  before do
    sign_in
  end

  context "upon sign-in" do
    it "shows the user's information" do
      expect(page).to have_content "My Dashboard"
      expect(page).to have_content "User Activity"
      expect(page).to have_content "User Notifications"

      within '.sidebar' do
        click_link "Works"
      end
      expect(page).to have_content "My Works"
      expect(page).to have_content "My Collections"
    end
  end
end

RSpec.describe "The dashboard as viewed by a regular user", type: :feature do
  before do
    sign_in
  end

  context "upon sign-in" do
    it "shows the user's information" do
      page.assert_text "My Dashboard"
      page.assert_text "User Activity"
      page.assert_text "User Notifications"

      within '.sidebar' do
        expect(page).to have_link "Works"
        expect(page).to have_link "Collections"
      end
    end
  end
end

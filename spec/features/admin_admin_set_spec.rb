RSpec.describe "The admin sets, through the admin dashboard" do
  let(:user) { create :admin }
  let(:title) { "Unique name: #{SecureRandom.hex}" }
  let(:admin_set) do
    create(:admin_set, title: [title],
                       description: ["A substantial description"],
                       edit_users: [user.user_key])
  end

  before do
    Hyrax::PermissionTemplate.create!(admin_set_id: admin_set.id)
  end

  scenario do
    login_as(user, scope: :user)
    visit '/dashboard'
    click_link "Administrative Sets"
    click_link title

    page.assert_text "A substantial description"
    page.assert_text "Works in This Set"

    click_link "Edit"
    within('#description') do
      fill_in "Title", with: 'A better unique name'
      click_button 'Save'
    end
    page.assert_text "A better unique name"
  end
end

require 'spec_helper'

RSpec.describe "The admin sets, through the admin dashboard" do
  let(:user) { create :user }

  before do
    create(:admin_set, title: ["A completely unique name"],
                       description: ["A substantial description"],
                       edit_users: [user.user_key])
    allow(RoleMapper).to receive(:byname).and_return(user.user_key => ['admin'])
  end

  scenario do
    login_as(user, scope: :user)
    visit '/admin'
    click_link "Administrative Sets"

    expect(page).to have_link "Create new administrative set"

    click_link "A completely unique name"

    expect(page).to have_content "A substantial description"
    expect(page).to have_content "Works in This Set"

    click_link "Edit"
    within('#description') do
      fill_in "Title", with: 'A better unique name'
      click_button 'Save'
    end
    expect(page).to have_content "A better unique name"
  end
end

require 'spec_helper'

RSpec.describe "The admin sets, through the admin dashboard" do
  let(:user) { create :user }

  before do
    create(:admin_set, title: ["A completely unique name"],
                       description: ["A substantial description"])
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

    fill_in "Title", with: 'A better unique name'
    click_button 'Save'
    expect(page).to have_content "A better unique name"
  end
end

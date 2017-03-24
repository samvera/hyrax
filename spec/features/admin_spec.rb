require 'spec_helper'

RSpec.describe "The admin dashboard" do
  let(:user) { create :admin }
  let(:admin_set_1) do
    create(:admin_set, title: ["First Admin Set"],
                       description: ["A description"],
                       edit_users: [user.user_key])
  end
  let(:admin_set_2) do
    create(:admin_set, title: ["Second Admin Set"],
                       description: ["A description"],
                       edit_users: [user.user_key])
  end

  before do
    create(:work_with_two_children, title: ["Work A"], admin_set_id: admin_set_1.id, edit_users: [user])
    create(:work_with_one_child, title: ["Work B"], admin_set_id: admin_set_2.id, edit_users: [user])
    create(:work_with_two_children, title: ["Work C"], admin_set_id: admin_set_2.id, edit_users: [user])
  end

  scenario do
    login_as(user, scope: :user)
    visit '/dashboard'

    expect(find('tr', text: 'First Admin Set').find('td:eq(2)')).to have_content(1)
    expect(find('tr', text: 'First Admin Set').find('td:eq(3)')).to have_content(2)

    expect(find('tr', text: 'Second Admin Set').find('td:eq(2)')).to have_content(2)
    expect(find('tr', text: 'Second Admin Set').find('td:eq(3)')).to have_content(3)
  end
end

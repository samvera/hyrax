RSpec.describe "The admin dashboard", :clean_repo do
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
    create(:work_with_files, title: ["Work A"], admin_set_id: admin_set_1.id, edit_users: [user])
    create(:work_with_one_file, title: ["Work B"], admin_set_id: admin_set_2.id, edit_users: [user])
    create(:work_with_file_and_work, title: ["Work C"], admin_set_id: admin_set_2.id, edit_users: [user])
  end

  it 'renders the counts of Works and Files in all AdminSets' do
    login_as(user, scope: :user)
    visit '/dashboard'

    expect(find('tr', text: 'First Admin Set').find('td:eq(2)')).to have_content(1)
    expect(find('tr', text: 'First Admin Set').find('td:eq(3)')).to have_content(2)

    expect(find('tr', text: 'Second Admin Set').find('td:eq(2)')).to have_content(2)
    expect(find('tr', text: 'Second Admin Set').find('td:eq(3)')).to have_content(2)
  end
end

RSpec.feature 'show admin set' do
  let(:admin_set) { FactoryGirl.create(:admin_set) }
  let(:admin) { FactoryGirl.create(:admin) }

  scenario "show admin set" do
    login_as admin
    expect(admin_set.description).to be_empty
    visit("/admin/admin_sets/#{admin_set.id}")
    expect(page).to have_content admin_set.title.first
  end
end

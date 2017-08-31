RSpec.describe "As an admin user I should be able to see all works" do
  let!(:work1) { create(:work, title: ['Testing #1']) }
  let!(:work2) { create(:work, title: ['Testing #2']) }

  before do
    sign_in create(:admin)
  end
  scenario do
    visit '/dashboard/works'
    page.assert_text 'Works'
    page.assert_text 'Testing #1'
    page.assert_text 'Testing #2'
  end
end

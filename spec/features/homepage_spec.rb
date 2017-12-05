RSpec.feature "The homepage" do
  let(:work1) { create_for_repository(:work, :public, title: ['Work 1']) }

  before do
    create(:featured_work, work_id: work1.id)
  end

  scenario 'it shows featured works' do
    visit root_path
    expect(page).to have_link "Work 1"
  end

  context "as an admin" do
    let(:user) { create(:admin) }

    before do
      sign_in user
    end

    scenario 'it shows featured works that I can sort' do
      visit root_path
      within '.dd-item' do
        expect(page).to have_link "Work 1"
      end
    end
  end
end

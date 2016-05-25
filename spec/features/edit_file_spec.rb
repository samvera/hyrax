describe "Editing a file:", type: :feature do
  let(:user) { create(:user) }
  let(:file_title) { 'Some kind of title' }
  let(:work) { build(:work, user: user) }
  let(:file) { work.members.first }

  before do
    sign_in user
    work.ordered_members << create(:file_set, user: user, title: [file_title])
    work.save!
  end

  context 'when the user tries to update file content, but forgets to select a file:' do
    it 'shows the edit page again' do
      visit edit_curation_concerns_file_set_path(file)
      click_link 'Versions'
      click_button 'Upload New Version'
      expect(page).to have_content "Edit #{file_title}"
    end
  end
end

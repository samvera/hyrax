RSpec.feature "Editing a file:", type: :feature do
  include ActionDispatch::TestProcess
  let(:user) { create(:user) }
  let(:file_title) { 'Some kind of title' }
  let(:file_set) do
    create_for_repository(:file_set,
                          user: user,
                          title: [file_title],
                          content: file)
  end
  let(:file) { fixture_file_upload('/world.png', 'image/png') }
  let(:work) do
    create_for_repository(:work, user: user, member_ids: [file_set.id])
  end

  before do
    sign_in user
  end

  context 'when the user tries to update file content, but forgets to select a file:' do
    it 'shows the edit page again' do
      visit edit_hyrax_file_set_path(file_set)
      click_link 'Versions'
      click_button 'Upload New Version'
      expect(page).to have_content "Edit #{file_title}"
    end
  end
end

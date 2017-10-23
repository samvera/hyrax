RSpec.feature "Editing a file:", type: :feature do
  let(:user) { create(:user) }
  let(:file_title) { 'Some kind of title' }
  let(:file_set) { create_for_repository(:file_set, user: user, title: [file_title]) }
  let(:file) { File.open(fixture_path + '/world.png') }
  let(:persister) { Valkyrie.config.metadata_adapter.persister }
  let(:work) do
    w = build(:work, user: user)
    w.member_ids += [file_set.id]
    w.read_groups = [] # TODO: is this required?
    persister.save(resource: w)
  end

  before do
    sign_in user
    Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
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

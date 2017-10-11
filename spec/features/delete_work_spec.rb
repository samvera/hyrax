RSpec.describe 'Deleting a work', type: :feature do
  let(:user) { create(:user) }
  let(:file_set) { create_for_repository(:file_set, user: user, title: ['ABC123xyz']) }
  let(:file) { File.open(fixture_path + '/world.png') }
  let(:persister) { Valkyrie.config.metadata_adapter.persister }
  let(:work) do
    w = build(:work, user: user)
    w.member_ids << file_set.id
    w.read_groups = [] # TODO: is this required?
    persister.save(resource: w)
  end

  before do
    sign_in user
    Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
  end

  context 'After deleting a work from the work show page' do
    it 'redirects to my dashboard' do
      visit hyrax_generic_work_path(work)
      click_on('Delete', match: :first)
      expect(page).to have_current_path(hyrax.my_works_path, only_path: true)
      expect(page).to have_content 'Deleted Test title'
    end
  end
end

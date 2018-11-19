RSpec.describe 'Deleting a work', type: :feature do
  let(:user) { create(:user) }
  let(:work) { build(:work, user: user) }
  let(:file_set) { create(:file_set, user: user, title: ['ABC123xyz']) }
  let(:file) { File.open(fixture_path + '/world.png') }

  before do
    sign_in user
    Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
    work.ordered_members << file_set
    work.read_groups = []
    work.save!
  end

  context 'After deleting a work from the work show page' do
    it 'redirects to my dashboard' do
      visit hyrax_generic_work_path(work)
      click_on('Delete', match: :first)
      expect(page).to have_current_path(hyrax.my_works_path, ignore_query: true)
      expect(page).to have_content 'Deleted Test title'
    end
  end
end

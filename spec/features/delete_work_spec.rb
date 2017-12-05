RSpec.describe 'Deleting a work', type: :feature do
  include ActionDispatch::TestProcess
  let(:user) { create(:user) }
  let(:file_set) do
    create_for_repository(:file_set,
                          user: user,
                          title: ['ABC123xyz'],
                          content: file)
  end
  let(:file) { fixture_file_upload('/world.png', 'image/png') }
  let(:work) do
    create_for_repository(:work, user: user, member_ids: [file_set.id])
  end

  before do
    sign_in user
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

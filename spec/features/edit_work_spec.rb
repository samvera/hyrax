RSpec.feature 'Editing a work', type: :feature do
  let(:user) { create(:user) }
  let(:work) { build(:work, user: user) }

  before do
    sign_in user
    work.ordered_members << create(:file_set, user: user, title: ['ABC123xyz'])
    work.read_groups = []
    work.save!
  end

  context 'when the user changes permissions' do
    it 'confirms copying permissions to files using Hyrax layout' do
      # e.g. /concern/generic_works/jq085k20z/edit
      visit edit_hyrax_generic_work_path(work)
      choose('generic_work_visibility_open')
      check('agreement')
      click_on('Save')
      page.assert_text 'Apply changes to contents?'
      page.assert_no_text "Powered by Hyrax"
    end
  end
end

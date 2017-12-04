RSpec.feature 'Editing a work', type: :feature do
  let(:user) { create(:user) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  let(:file_set) { create_for_repository(:file_set, user: user, title: ['ABC123xyz']) }
  let(:work) do
    w = build(:work, user: user)
    w.member_ids += [file_set.id]
    w.read_groups = [] # TODO: is this required?
    persister.save(resource: w)
  end

  before do
    sign_in user
  end

  context 'when the user changes permissions' do
    it 'confirms copying permissions to files using Hyrax layout' do
      # e.g. /concern/generic_works/jq085k20z/edit
      visit edit_hyrax_generic_work_path(work)
      choose('generic_work_visibility_open')
      check('agreement')
      click_on('Save')
      expect(page).to have_content 'Apply changes to contents?'
      expect(page).not_to have_content "Powered by Hyrax"
    end
  end
end

# frozen_string_literal: true
RSpec.describe "Editing a file:", type: :feature do
  let(:user) { create(:user) }
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { create(:permission_template, source_id: admin_set.id) }
  let!(:workflow) { create(:workflow, allows_access_grant: true, active: true, permission_template_id: permission_template.id) }
  let(:file_title) { 'Some kind of title' }
  let(:work) { build(:work, user: user, admin_set_id: admin_set.id) }
  let(:file_set) { create(:file_set, user: user, title: [file_title]) }
  let(:file) { File.open(fixture_path + '/world.png') }

  before do
    sign_in user
    Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
    work.ordered_members << file_set
    work.save!
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

require 'spec_helper'

describe "Editing a file:", type: :feature do
  let(:user) { create(:user) }
  let(:file_title) { 'Some kind of title' }
  let(:work) { create(:work_with_one_file, user: user) }
  let(:file) { work.members.first }

  before { sign_in user }

  context 'when the user tries to update file content, but forgets to select a file:' do
    it 'displays an error' do
      visit edit_curation_concerns_file_set_path(file)
      click_link 'Versions'
      click_button 'Upload New Version'
      expect(page).to have_content "Edit #{file_title}"
      expect(page).to have_content 'Please select a file'
    end
  end
end

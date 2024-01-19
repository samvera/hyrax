# frozen_string_literal: true
RSpec.describe 'Deleting a work', type: :feature do
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.valkyrie_create(:comet_in_moominland, depositor: user.user_key, edit_users: [user], members: [file_set]) }
  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :with_files, read_users: [user], title: ['ABC123xyz']) }

  before { sign_in user }

  context 'After deleting a work from the work show page' do
    it 'redirects to my dashboard' do
      visit hyrax_monograph_path(work)

      click_on('Delete', match: :first)
      expect(page).to have_current_path(hyrax.my_works_path, ignore_query: true)
      expect(page).to have_content work.title.first
    end
  end
end

# frozen_string_literal: true
RSpec.describe 'Creating a new Work as admin', :js, :workflow, :clean_repo, perform_enqueued: [AttachFilesToWorkJob, IngestJob] do
  let(:user) { create(:admin) }

  before do
    Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    valkyrie_create(:hyrax_admin_set, :with_permission_template, title: ['Another Admin Set'], user: user)
  end

  context 'when there are multiple admin sets' do
    before do
      sign_in user
    end

    it "allows default admin set to be the first item in the select menu" do
      visit '/dashboard'
      click_link 'Works'
      find('#add-new-work-button').click
      choose "payload_concern", option: "GenericWork"
      click_button 'Create work'
      click_link "Relationship" # switch tab
      expect(page).to have_content('Administrative Set')
      expect(page).to have_content('Another Admin Set')
      expect(page).to have_content('Default Admin Set')
      expect(page).to have_selector('select#generic_work_admin_set_id')
      expect(page).to have_select('generic_work_admin_set_id', selected: 'Default Admin Set')
    end
  end
end

# frozen_string_literal: true
RSpec.describe 'Deposit Agreement options', :js, :workflow, :clean_repo do
  let(:user) { create(:user) }
  let(:admin_user) { create(:admin) }
  # let(:adminset) { create(:admin_set) }
  let!(:ability) { ::Ability.new(user) }
  let(:permission_template) { create(:permission_template, with_admin_set: true, with_active_workflow: true) }

  before do
    # Grant the user access to deposit into an admin set.
    create(:permission_template_access, :deposit, permission_template: permission_template, agent_type: 'user', agent_id: user.user_key)
    # stub out characterization
    allow(CharacterizeJob).to receive(:perform_later)
  end

  context "with activate deposit agreement off" do
    before do
      sign_in admin_user
      # Disable active agreements
      visit "/admin/features"
      first("tr[data-feature='active-deposit-agreement-acceptance'] input[value='off']").click

      sign_in user
      click_link 'Works'
      find('#add-new-work-button').click
      choose "payload_concern", option: "GenericWork"
      click_button 'Create work'
    end

    it "allows saving work when active deposit agreement is off" do
      # Fill in required metadata
      fill_in('Title', with: 'My Test Work')
      fill_in('Creator', with: 'Doe, Jane')
      select('In Copyright', from: 'Rights statement')

      # Add a file
      click_link "Files"
      within('div#add-files') do
        attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
      end

      expect(page).not_to have_selector('#agreement')
      click_on('Save')
      expect(page).to have_content('My Test Work')
      expect(page).to have_content "Your files are being processed by #{I18n.t('hyrax.product_name')} in the background."
    end
  end
end
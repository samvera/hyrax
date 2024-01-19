# frozen_string_literal: true
RSpec.describe 'Creating a new Work', :js, :workflow, :clean_repo do
  let(:user) { create(:user) }
  let!(:ability) { ::Ability.new(user) }
  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  let!(:uploaded_file1) { Hyrax::UploadedFile.create(file: file1, user: user) }
  let!(:uploaded_file2) { Hyrax::UploadedFile.create(file: file2, user: user) }
  let(:permission_template) { create(:permission_template, with_admin_set: true, with_active_workflow: true) }

  before do
    # Grant the user access to deposit into an admin set.
    create(:permission_template_access, :deposit, permission_template: permission_template, agent_type: 'user', agent_id: user.user_key)
    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    allow(CharacterizeJob).to receive(:perform_later)
  end

  context "when the user is not a proxy" do
    before do
      sign_in user
      click_link 'Works'
      find('#add-new-work-button').click
      choose "payload_concern", option: "GenericWork"
      click_button 'Create work'
    end

    it 'creates the work' do
      click_link "Files" # switch tab
      expect(page).to have_content "Add files"
      expect(page).to have_content "Add folder"
      within('div#add-files') do
        attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
        attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/jp2_fits.xml", visible: false)
      end
      click_link "Descriptions" # switch tab
      fill_in('Title', with: 'My Test Work')
      fill_in('Creator', with: 'Doe, Jane')
      select('In Copyright', from: 'Rights statement')
      # With selenium and the chrome driver, focus remains on the
      # select box. Click outside the box so the next line can't find
      # its element
      find('body').click
      choose('generic_work_visibility_open')
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      check('agreement')
      # These lines are for debugging, should this test fail
      # puts "Required metadata: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').requiredFields.areComplete})}"
      # puts "Required files: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').uploads.hasFiles})}"
      # puts "Agreement : #{page.evaluate_script(%{$('#form-progress').data('save_work_control').depositAgreement.isAccepted})}"
      click_on('Save')
      expect(page).to have_content('My Test Work')
      expect(page).to have_content "Your files are being processed by #{I18n.t('hyrax.product_name')} in the background."
    end
  end

  context 'when the user is a proxy', perform_enqueued: [AttachFilesToWorkJob, IngestJob, ValkyrieIngestJob] do
    let(:second_user) { create(:user) }

    before do
      create(:permission_template_access, :deposit, permission_template: permission_template, agent_type: 'user', agent_id: second_user.user_key)
      ProxyDepositRights.create!(grantor: second_user, grantee: user)
      sign_in user
      click_link 'Works'
      find('#add-new-work-button').click
      choose "payload_concern", option: "GenericWork"
      click_button 'Create work'
    end

    it "allows on-behalf-of deposit" do
      click_link "Files" # switch tab
      expect(page).to have_content "Add files"
      within('div#add-files') do
        attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
        attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/jp2_fits.xml", visible: false)
      end
      click_link "Descriptions" # switch tab
      fill_in('Title', with: 'My Test Work')
      fill_in('Creator', with: 'Doe, Jane')
      select('In Copyright', from: 'Rights statement')
      # With selenium and the chrome driver, focus remains on the
      # select box. Click outside the box so the next line can't find
      # its element
      find('body').click
      choose('generic_work_visibility_open')
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      select(second_user.user_key, from: 'Proxy Depositors - Select the user on whose behalf you are depositing')
      check('agreement')
      # These lines are for debugging, should this test fail
      # puts "Required metadata: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').requiredFields.areComplete})}"
      # puts "Required files: #{page.evaluate_script(%{$('#form-progress').data('save_work_control').uploads.hasFiles})}"
      # puts "Agreement : #{page.evaluate_script(%{$('#form-progress').data('save_work_control').depositAgreement.isAccepted})}"
      click_on('Save')
      expect(page).to have_content('My Test Work')
      expect(page).to have_content "Your files are being processed by #{I18n.t('hyrax.product_name')} in the background."

      sign_in second_user
      click_link 'Works'
      expect(page).to have_content "My Test Work"

      # check that user can get to the files
      within('.media-body') do
        click_link "My Test Work"
      end
      click_link "image.jp2"
      expect(page).to have_content "image.jp2"

      visit '/dashboard'
      click_link 'Works'

      within('.media-body') do
        click_link "My Test Work"
      end
      click_link "jp2_fits.xml"
      expect(page).to have_content "jp2_fits.xml"
    end
  end

  context "when a file uploaded and then deleted" do
    before do
      allow(Hyrax.config).to receive(:work_requires_files?).and_return(true)

      sign_in user
      click_link 'Works'
      find('#add-new-work-button').click
      choose "payload_concern", option: "GenericWork"
      click_button 'Create work'
    end

    it 'updates the required file check status' do
      click_link "Files" # switch to the Files tab
      within('div#add-files') do
        attach_file("files[]", "#{Hyrax::Engine.root}/spec/fixtures/image.jp2", visible: false)
      end

      expect(page).to have_css('ul li#required-files.complete', text: 'Add files')
      click_button 'Delete' # delete the file
      expect(page).to have_css('ul li#required-files.incomplete', text: 'Add files')
    end
  end

  context "with valkyrie resources", valkyrie_adapter: :postgres_adapter do
    before do
      sign_in user
      click_link 'Works'
      click_link "Add New Work"
      choose "payload_concern", option: "GenericWork"
      click_button 'Create work'
    end

    it "allows user to set an embargo" do
      expect(page).to have_field("generic_work_visibility_embargo", disabled: false)
    end
  end
end

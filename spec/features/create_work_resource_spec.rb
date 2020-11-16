# frozen_string_literal: true
RSpec.describe 'Creating a new Hyrax::Work Resource', :js, :workflow, :clean_repo do
  let(:user) { create(:user) }
  let!(:ability) { ::Ability.new(user) }
  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  # TODO(k8): update to use Valkyrie
  let!(:uploaded_file1) { Hyrax::UploadedFile.create(file: file1, user: user) }
  let!(:uploaded_file2) { Hyrax::UploadedFile.create(file: file2, user: user) }

  before do
    visit root_path
    # Grant the user access to deposit into an admin set.
    create(:permission_template_access,
           :deposit,
           permission_template: create(:permission_template, with_admin_set: true, with_active_workflow: true),
           agent_type: 'user',
           agent_id: user.user_key)
    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    allow(CharacterizeJob).to receive(:perform_later)
  end

  context "when the user is not a proxy" do
    before do
      sign_in user
      click_link 'Works'
      click_link "Add new work"
      # Monograph is a Valkyrie resource
      choose "payload_concern", option: "Monograph"
      click_button 'Create work'
    end

    it 'generates the form based on the metadata yaml configs' do
      # test required=true fields are marked with an asterisk (e.g. core title)
      expect(page).to have_content "Title"
      # TODO: How to check that `<span class="class="label label-info required-tag"> follows title?`

      # test required=false fields are not marked with an asterisk (e.g. monograph - need to define field)
      # TODO: Define field in monograph that uses required=false
      # TODO: expect the content and check that the <span> for required isn't present

      # test primary=true fields are above the fold (e.g. basic Rights statement)
      expect(page).to have_content "Rights statement"
      # TODO: How to verify that Rights statement is not in the hidden area?

      # test primary=false fields are below the fold (e.g. basic Alternative title)
      # TODO: Not sure whether hidden is findable with have_content.  If not, this will work.
      expect(page).not_to have_content "Alternative title"
      click_button 'Additional fields'
      # TODO: Not sure whether hidden is findable with have_content.  If not showing the fields first and then looking for content should work.
      expect(page).to have_content "Alternative title"
      # TODO: If hidden areas are findable by have_content, then how to verify that Rights statement is in the hidden area?

      # test multiple=true fields have '+ Add another ...' (e.g. monograph - need to define field)
      # TODO: Define field in monograph that uses multiple=true
      # TODO: expect the content and check that after its field, there is `<span class="controls-add-text">Add another _FIELD_NAME_</span>`

      # test multiple=false fields do not have '+ Add another ...' (e.g. monograph - need to define field)
      # TODO: Define field in monograph that uses multiple=false
      # TODO: expect the content and check that after its field, there isn't `<span class="controls-add-text">Add another _FIELD_NAME_</span>`

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
      expect(page).to have_content "Your files are being processed by Hyrax in the background."
    end
  end

  context 'when the user is a proxy', perform_enqueued: [ContentDepositorChangeEventJob, AttachFilesToWorkJob, IngestJob] do
    let(:second_user) { create(:user) }

    before do
      ProxyDepositRights.create!(grantor: second_user, grantee: user)
      sign_in user
      click_link 'Works'
      click_link "Add new work"
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
      expect(page).to have_content "Your files are being processed by Hyrax in the background."

      sign_in second_user
      click_link 'Works'
      expect(page).to have_content "My Test Work"

      # check that user can get to the files
      within('.media-heading') do
        click_link "My Test Work"
      end
      click_link "image.jp2"
      expect(page).to have_content "image.jp2"

      visit '/dashboard'
      click_link 'Works'

      within('.media-heading') do
        click_link "My Test Work"
      end
      click_link "jp2_fits.xml"
      expect(page).to have_content "jp2_fits.xml"
    end
  end

  context "when a file uploaded and then deleted" do
    before do
      sign_in user
      click_link 'Works'
      click_link "Add new work"
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
end

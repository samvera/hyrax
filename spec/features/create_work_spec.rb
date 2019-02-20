RSpec.describe 'Creating a new Work', :js, :workflow do
  let(:user) { create(:user) }
  let!(:ability) { ::Ability.new(user) }
  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  let!(:uploaded_file1) { Hyrax::UploadedFile.create(file: file1, user: user) }
  let!(:uploaded_file2) { Hyrax::UploadedFile.create(file: file2, user: user) }

  before do
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
      choose "payload_concern", option: "GenericWork"
      click_button 'Create work'
    end

    it 'creates the work' do
      click_link "Files" # switch tab
      expect(page).to have_content "Add files"
      expect(page).to have_content "Add folder"
      within('span#addfiles') do
        attach_file("files[]", "fixtures/image.jp2", visible: false)
        attach_file("files[]", "fixtures/jp2_fits.xml", visible: false)
      end
      click_link "Descriptions" # switch tab
      fill_in('Title', with: 'My Test Work')
      fill_in('Creator', with: 'Doe, Jane')
      fill_in('Keyword', with: 'testing')
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
      within('span#addfiles') do
        attach_file("files[]", "fixtures/image.jp2", visible: false)
        attach_file("files[]", "fixtures/jp2_fits.xml", visible: false)
      end
      click_link "Descriptions" # switch tab
      fill_in('Title', with: 'My Test Work')
      fill_in('Creator', with: 'Doe, Jane')
      fill_in('Keyword', with: 'testing')
      select('In Copyright', from: 'Rights statement')
      # With selenium and the chrome driver, focus remains on the
      # select box. Click outside the box so the next line can't find
      # its element
      find('body').click
      choose('generic_work_visibility_open')
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      select(second_user.user_key, from: 'On behalf of')
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
      within('span#addfiles') do
        attach_file("files[]", "fixtures/image.jp2", visible: false)
      end
      expect(page).to have_css('ul li#required-files.complete', text: 'Add files')
      click_button 'Delete' # delete the file
      expect(page).to have_css('ul li#required-files.incomplete', text: 'Add files')
    end
  end
end

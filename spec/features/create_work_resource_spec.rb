# frozen_string_literal: true
RSpec.describe 'Creating a new Hyrax::Work Resource', :js, :workflow, :feature do
  let(:user) { create(:user) }
  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:file2) { File.open(fixture_path + '/image.jp2') }
  let!(:uploaded_file1) { Hyrax::UploadedFile.create(file: file1, user: user) }
  let!(:uploaded_file2) { Hyrax::UploadedFile.create(file: file2, user: user) }

  before do
    Hyrax::EnsureWellFormedAdminSetService.call
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
      # test required=true fields are marked with an asterisk (e.g. monograph record_info)
      expect(page.find('div.monograph_record_info label', text: 'Record info')[:class]).to include('required')

      # test required=false fields are not marked with an asterisk (e.g. monograph place_of_publication)
      expect(page.find('div.monograph_place_of_publication label', text: 'Place of publication')[:class]).not_to include('required')

      # test primary=true fields are above the fold (e.g. monograph genre)
      expect(page).to have_content "Genre"

      # test primary=false fields are below the fold (e.g. monograph series_title)
      expect(page).not_to have_content "Series title"
      click_link 'Additional fields' # show secondary fields
      expect(page).to have_content "Series title"

      # test multiple=true fields have '+ Add another ...' (e.g. monograph target_audience)
      expect(page).to have_content "Add another Target audience"

      # test multiple=false fields do not have '+ Add another ...' (e.g. monograph table_of_contents)
      expect(page).not_to have_content "Add another Table of contents"

      # test field without form configs (e.g. monograph date_of_issuance)
      expect(page).not_to have_content "Date of issuance"
    end
  end
end

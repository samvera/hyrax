# frozen_string_literal: true

RSpec.describe 'Batch creation of works', type: :feature do
  let(:user) { create(:user) }
  let!(:default_admin_set) do
    build(:admin_set,
          id: AdminSet::DEFAULT_ID,
          title: ["Default Admin Set"],
          description: ["A description"],
          with_permission_template: { deposit_groups: [::Ability.registered_group_name] })
  end

  before { sign_in user }

  it "renders the batch create form" do
    visit hyrax.new_batch_upload_path
    expect(page).to have_content "Add New Works by Batch"
    within("li.active") do
      expect(page).to have_content("Files")
    end
    expect(page).to have_content("Each file will be uploaded to a separate new work resulting in one work per uploaded file.")
  end

  context 'when the user is a proxy', :js, :workflow, :perform_enqueued do
    let(:second_user) { create(:user) }

    before do
      allow(CharacterizeJob).to receive(:perform_later).and_return(true)
      allow(CreateDerivativesJob).to receive(:perform_later).and_return(true)

      ProxyDepositRights.create!(grantor: second_user, grantee: user)
      sign_in user
      click_link 'Works'
      click_link "Create batch of works"
      choose "payload_concern", option: "GenericWork"
      click_button 'Create work'
    end

    it "allows on-behalf-of batch deposit", :js do
      click_link "Files" # switch tab
      expect(page).to have_content "Add files"
      within('span#addfiles') do
        # two arbitrary files that aren't actually related, but should be
        # small enough to require minimal processessing.
        attach_file("files[]", "fixtures/small_file.txt", visible: false)
        attach_file("files[]", "fixtures/png_fits.xml", visible: false)
      end
      click_link "Descriptions" # switch tab
      fill_in('Creator', with: 'Doe, Jane')
      fill_in('Keyword', with: 'testing')
      select('In Copyright', from: 'Rights statement')
      # With selenium and the chrome driver, focus remains on the
      # select box. Click outside the box so the next line can't find
      # its element
      find('body').click

      choose('batch_upload_item_visibility_open')
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      select(second_user.user_key, from: 'On behalf of')
      check('agreement')
      click_on('Save')

      # Expect the proxy depositor (grantor) to be able to see both uploaded files.
      expect(page).to have_content 'small_file.txt'
      expect(page).to have_content 'png_fits.xml'

      # Sign in with the grantee user, and expect to see the works deposited
      # on their behalf.
      sign_in second_user
      click_link 'Works'
      expect(page).to have_content 'small_file.txt'
      expect(page).to have_content 'png_fits.xml'
    end
  end
end

require 'spec_helper'
# require 'redlock'

feature 'Creating a new Work', :js do
  let(:user) { create(:user) }

  # let(:redlock_client_stub) { # stub out redis connection
  #   client = double('redlock client')
  #   allow(client).to receive(:lock).and_yield(true)
  #   allow(Redlock::Client).to receive(:new).and_return(client)
  #   client
  # }

  before do
    sign_in user
    click_link "Create Work"

    allow(CharacterizeJob).to receive(:perform_later)
    # redlock_client_stub
  end

  it 'creates the work' do
    click_link "Files" # switch tab
    expect(page).to have_content "Add files"
    expect(page).to have_content "Start upload"
    expect(page).to have_content "Cancel upload"

    attach_file("files[]", File.dirname(__FILE__) + "/../../spec/fixtures/image.jp2", visible: false)
    attach_file("files[]", File.dirname(__FILE__) + "/../../spec/fixtures/jp2_fits.xml", visible: false)

    click_button "Start upload"

    click_link "Metadata" # switch tab
    fill_in('Title', with: 'My Test Work')

    choose('generic_work_visibility_open')
    expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
    # attach_file('Upload a file', fixture_file_path('files/image.png'))
    check('agreement')
    click_on('Save')
    expect(page).to have_content('My Test Work (Generic Work)')
    expect(page).to have_content "Your files are being processed by Repository in the background."
  end
end

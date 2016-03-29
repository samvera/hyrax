require 'spec_helper'
# require 'redlock'

feature 'Creating a new Work' do
  let(:user) { create(:user) }

  # let(:redlock_client_stub) { # stub out redis connection
  #   client = double('redlock client')
  #   allow(client).to receive(:lock).and_yield(true)
  #   allow(Redlock::Client).to receive(:new).and_return(client)
  #   client
  # }

  before do
    sign_in user

    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    # expect(CharacterizeJob).to receive(:perform_later)
    # redlock_client_stub
  end

  it 'creates the work' do
    visit root_path
    work_title = 'My Test Work'
    click_link 'Share Your Work'
    within('form.new_generic_work') do
      fill_in('Title', with: work_title)
      choose('visibility_open')
      # attach_file('Upload a file', fixture_file_path('files/image.png'))
      click_on('Save')
    end
    expect(page).to have_content('My Test Work (Generic Work)')
  end
end

require 'spec_helper'
require 'redlock'

feature 'Creating a new Work' do
  let(:user) { FactoryGirl.create(:user) }

  let(:redlock_client_stub) { # stub out redis connection
    client = double('redlock client')
    allow(client).to receive(:lock).and_yield(true)
    allow(Redlock::Client).to receive(:new).and_return(client)
    client
  }

  before do
    sign_in user

    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    expect(CharacterizeJob).to receive(:perform_later)
    redlock_client_stub
  end

  it 'creates the work and allow you to attach a file' do
    visit '/concern/generic_works/new'
    work_title = 'My Test Work'
    within('form.new_generic_work') do
      fill_in('Title', with: work_title)
      attach_file('Upload a file', fixture_file_path('files/image.png'))
      choose('generic_work_visibility_open')
      click_on('Create Generic work')
    end
    within '.related_files' do
      expect(page).to have_link 'image.png'
    end

    title = 'Genealogies of the American West'
    click_link 'Add a Collection'
    fill_in('Title', with: title)
    click_button('Create Collection')
    click_on('Add files from your dashboard')
    find('#facet-human_readable_type_sim').click_link('Generic Work')

    # Works can be added to collections
    within('.modal.fade', match: :first) do
      select title, from: 'id'
      click_on('Add to collection')
    end
    expect(page).to have_content('Collection was successfully updated.')
    expect(page).to have_content(work_title)
  end
end

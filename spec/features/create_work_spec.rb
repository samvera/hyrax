require 'spec_helper'
require 'redlock'

feature 'Creating a new Work', :workflow do
  let(:user) { FactoryGirl.create(:user) }

  let(:redlock_client_stub) { # stub out redis connection
    client = double('redlock client')
    allow(client).to receive(:lock).and_yield(true)
    allow(Redlock::Client).to receive(:new).and_return(client)
    client
  }

  before do
    col = Collection.new title: ['Test Collection']
    col.apply_depositor_metadata user.user_key
    col.save!
    sign_in user

    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    allow(CharacterizeJob).to receive(:perform_later)
    redlock_client_stub
  end

  it 'creates the work and allow you to attach a file' do
    visit '/concern/generic_works/new'
    work_title = 'My Test Work'
    source = 'related resource'
    within('form.new_generic_work') do
      fill_in('Title', with: work_title)
      fill_in('Source', with: source)
      select 'Attribution 3.0 United States', from: 'generic_work[rights][]'
      attach_file('Upload a file', fixture_file_path('files/image.png'))
      choose('generic_work_visibility_open')
      select 'Test Collection', from: 'generic_work[member_of_collection_ids][]'
      click_on('Create Generic work')
    end

    expect(page).to have_content(source)
    expect(page).to have_link 'Attribution 3.0 United States',
                              href: 'http://creativecommons.org/licenses/by/3.0/us/'

    within '.related_files' do
      expect(page).to have_link 'image.png'
    end

    within '.member_of_collections' do
      expect(page).to have_link 'Test Collection'
    end
  end
end

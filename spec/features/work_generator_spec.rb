require 'spec_helper'
require 'rails/generators'
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
    Rails::Generators.invoke('curation_concerns:work', ['Catapult'], destination_root: Rails.root)
    load "#{EngineCart.destination}/app/models/catapult.rb"
    load "#{EngineCart.destination}/app/controllers/curation_concerns/catapults_controller.rb"
    load "#{EngineCart.destination}/app/actors/curation_concerns/catapult_actor.rb"
    load "#{EngineCart.destination}/app/forms/curation_concerns/catapult_form.rb"
    load "#{EngineCart.destination}/config/initializers/curation_concerns.rb"
    load "#{EngineCart.destination}/config/routes.rb"
    load "app/helpers/curation_concerns/url_helper.rb"
    sign_in user

    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    expect(CharacterizeJob).to receive(:perform_later)
    redlock_client_stub
  end

  after do
    Rails::Generators.invoke('curation_concerns:work', ['Catapult'], behavior: :revoke, destination_root: Rails.root)
  end

  it 'catapults should behave like generic works' do
    visit '/concern/catapults/new'
    # within("form.new_file_set") do
    #   attach_file("Upload a file", fixture_file_path('files/image.png'))
    #   click_button "Attach to Generic Work"
    # end
    catapult_title = 'My Test Work'
    within('form.new_catapult') do
      fill_in('Title', with: catapult_title)
      attach_file('Upload a file', fixture_file_path('files/image.png'))
      choose('catapult_visibility_open')
      click_on('Create Catapult')
    end
    click_on('Edit This Catapult')
    within('form.edit_catapult') do
      fill_in('Subject', with: 'test')
      click_on('Update Catapult')
    end
    title = 'Genealogies of the American West'
    click_link 'Add a Collection'
    fill_in('Title', with: title)
    click_button('Create Collection')
    click_on('Add files from your dashboard')
    find('#facet-human_readable_type_sim').click_link('Catapult')
    within('.modal.fade', match: :first) do
      select title, from: 'id'
      click_on('Add to collection')
    end
    expect(page).to have_content('Collection was successfully updated.')
    expect(page).to have_content(catapult_title)
  end
end

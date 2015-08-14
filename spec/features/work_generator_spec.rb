require 'spec_helper'
require 'rails/generators'

describe 'Creating a new Work' do
  let(:user) { FactoryGirl.create(:user) }

  before do
    Rails::Generators.invoke('curation_concerns:work', ['Catapult'], destination_root: Rails.root)
    load 'spec/internal/app/models/catapult.rb'
    load 'spec/internal/app/controllers/curation_concerns/catapults_controller.rb'
    load 'spec/internal/app/actors/curation_concerns/catapult_actor.rb'
    load 'spec/internal/config/initializers/curation_concerns_config.rb'
    load 'spec/internal/config/routes.rb'
    load 'app/helpers/curation_concerns/url_helper.rb'
    sign_in user

    # stub out characterization. Travis doesn't have fits installed, and it's not relevant to the test.
    s2 = double('resque message')
    expect(CharacterizeJob).to receive(:new).and_return(s2)
    expect(CurationConcerns.queue).to receive(:push).with(s2).once
  end

  after do
    Rails::Generators.invoke('curation_concerns:work', ['Catapult'], behavior: :revoke, destination_root: Rails.root)
  end

  it 'catapults should behave like generic works' do
    visit '/concern/catapults/new'
    # within("form.new_generic_file") do
    #   attach_file("Upload a file", fixture_file_path('files/image.png'))
    #   click_button "Attach to Generic Work"
    # end
    catapult_title = 'My Test Work'
    within('form.new_catapult') do
      fill_in('Title', with: catapult_title)
      attach_file('Upload a file', fixture_file_path('files/image.png'))
      choose('visibility_open')
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

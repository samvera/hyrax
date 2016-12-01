require 'spec_helper'
require 'rails/generators'
require 'redlock'

feature 'Creating a new Work', :workflow do
  before do
    Rails::Generators.invoke('sufia:work', ['Catapult'], destination_root: Rails.root)
    load "#{EngineCart.destination}/app/models/catapult.rb"
    load "#{EngineCart.destination}/app/controllers/sufia/catapults_controller.rb"
    load "#{EngineCart.destination}/app/actors/sufia/actors/catapult_actor.rb"
    load "#{EngineCart.destination}/app/forms/sufia/catapult_form.rb"
    load "#{EngineCart.destination}/config/initializers/sufia.rb"
    load "#{EngineCart.destination}/config/routes.rb"
    load "app/helpers/sufia/url_helper.rb"
  end

  after do
    Rails::Generators.invoke('sufia:work', ['Catapult'], behavior: :revoke, destination_root: Rails.root)
  end

  it 'catapults should behave like generic works' do
    expect(Sufia.config.curation_concerns).to include Catapult
    expect(defined? Sufia::Actors::CatapultActor).to eq 'constant'
    expect(defined? Sufia::CatapultsController).to eq 'constant'
    expect(defined? Sufia::CatapultForm).to eq 'constant'
  end
end

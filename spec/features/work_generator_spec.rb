require 'spec_helper'
require 'rails/generators'
require 'redlock'

feature 'Creating a new Work', :workflow do
  before do
    Rails::Generators.invoke('hyrax:work', ['Catapult', '--quiet'], destination_root: Rails.root)
    load "#{EngineCart.destination}/app/models/catapult.rb"
    load "#{EngineCart.destination}/app/controllers/hyrax/catapults_controller.rb"
    load "#{EngineCart.destination}/app/actors/hyrax/actors/catapult_actor.rb"
    load "#{EngineCart.destination}/app/forms/hyrax/catapult_form.rb"
    load "#{EngineCart.destination}/config/initializers/hyrax.rb"
    load "#{EngineCart.destination}/config/routes.rb"
    load "app/helpers/hyrax/url_helper.rb"
  end

  after do
    Rails::Generators.invoke('hyrax:work', ['Catapult', '--quiet'], behavior: :revoke, destination_root: Rails.root)
  end

  it 'catapults should behave like generic works' do
    expect(Hyrax.config.curation_concerns).to include Catapult
    expect(defined? Hyrax::Actors::CatapultActor).to eq 'constant'
    expect(defined? Hyrax::CatapultsController).to eq 'constant'
    expect(defined? Hyrax::CatapultForm).to eq 'constant'
  end
end

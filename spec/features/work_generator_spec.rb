# frozen_string_literal: true
require 'rails/generators'
require 'redlock'

RSpec.describe 'Creating a new Work' do
  before do
    Rails::Generators.invoke('hyrax:work', ['Catapult', '--quiet'], destination_root: Rails.root)
    load Rails.root.join('app', 'indexers', 'catapult_indexer.rb')
    load Rails.root.join('app', 'models', 'catapult.rb')
    load Rails.root.join('app', 'presenters', 'hyrax', 'catapult_presenter.rb')
    load Rails.root.join('app', 'controllers', 'hyrax', 'catapults_controller.rb')
    load Rails.root.join('app', 'actors', 'hyrax', 'actors', 'catapult_actor.rb')
    load Rails.root.join('app', 'forms', 'hyrax', 'catapult_form.rb')
    load Rails.root.join('config', 'initializers', 'hyrax.rb')
    load Rails.root.join('config', 'routes.rb')
  end

  after do
    Rails::Generators.invoke('hyrax:work', ['Catapult', '--quiet'], behavior: :revoke, destination_root: Rails.root)
    Hyrax::ModelRegistry.instance_variable_set(:@work_class_names, nil) # Catapult gets memoized here
  end

  it 'catapults should behave like generic works' do
    expect(Hyrax.config.curation_concerns).to include Catapult
    expect(defined? Hyrax::Actors::CatapultActor).to eq 'constant'
    expect(Hyrax::CatapultsController.show_presenter).to eq Hyrax::CatapultPresenter
    expect(defined? Hyrax::CatapultForm).to eq 'constant'
    expect(Catapult.indexer).to eq CatapultIndexer
  end
end

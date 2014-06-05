# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("config/environment", ENV['RAILS_ROOT'] || File.expand_path("../internal", __FILE__))

require 'database_cleaner'

require 'rspec/rails'
require 'rspec/its'
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = ENV['TRAVIS'] ? 30 : 15
require 'capybara/rspec'
require 'capybara/rails'
require 'equivalent-xml/rspec_matchers'

require File.expand_path('../support/features', __FILE__)


if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails'
  SimpleCov.command_name "spec"
end

$in_travis = !ENV['TRAVIS'].nil? && ENV['TRAVIS'] == 'true'

if $in_travis
  # Monkey-patches the FITS runner to return the PDF FITS fixture
  module Hydra
    module Derivatives
      module ExtractMetadata
        def extract_metadata
          return unless has_content?
          Hydra::FileCharacterization.characterize(content, filename_for_characterization, :fits) do |config|
            config[:fits] = lambda { |filename|
              filename = File.expand_path("../fixtures/pdf_fits.xml", __FILE__)
              File.read(filename)
            }
          end
        end
      end
    end
  end
end

if defined?(ClamAV)
  ClamAV.instance.loaddb
else
  class ClamAV
    include Singleton
    def scanfile(f)
      0
    end
    def loaddb
      nil
    end
  end
end

Resque.inline = Rails.env.test?

FactoryGirl.definition_file_paths = [File.expand_path("../factories", __FILE__)]
FactoryGirl.find_definitions

module EngineRoutes
  def self.included(base)
    base.routes { Sufia::Engine.routes }
  end
  def main_app
    Rails.application.class.routes.url_helpers
  end
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = File.expand_path("../fixtures", __FILE__)

  config.use_transactional_fixtures = false

  config.before :each do
    if Capybara.current_driver == :rack_test
      DatabaseCleaner.strategy = :transaction
    else
      DatabaseCleaner.strategy = :truncation
    end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end


  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.include Devise::TestHelpers, type: :controller
  config.include EngineRoutes, type: :controller
  config.include EquivalentXml::RSpecMatchers

  config.include Warden::Test::Helpers, type: :feature
  config.after(:each, type: :feature) { Warden.test_reset! }
  config.infer_spec_type_from_file_location!
end

module FactoryGirl
  def self.find_or_create(handle, by=:email)
    tmpl = FactoryGirl.build(handle)
    tmpl.class.send("find_by_#{by}".to_sym, tmpl.send(by)) || FactoryGirl.create(handle)
  end
end

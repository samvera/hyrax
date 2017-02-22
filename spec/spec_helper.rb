ENV["RAILS_ENV"] ||= 'test'
require "bundler/setup"

def coverage_needed?
  ENV['COVERAGE'] || ENV['TRAVIS']
end

if coverage_needed?
  require 'simplecov'
  require 'coveralls'
  SimpleCov.root(File.expand_path('../..', __FILE__))
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start('rails') do
    add_filter '/.internal_test_app'
    add_filter '/lib/generators'
    add_filter '/spec'
    add_filter '/tasks'
    add_filter '/lib/hyrax/version.rb'
    add_filter '/lib/hyrax/engine.rb'
  end
  SimpleCov.command_name 'spec'
end

require 'factory_girl'
require 'engine_cart'
EngineCart.load_application!

require 'devise'
require 'devise/version'
require 'mida'
require 'active_fedora/noid/rspec'
require 'rails-controller-testing'
require 'rspec/rails'
require 'rspec/its'
require 'rspec/matchers'
require 'rspec/active_model/mocks'
require 'capybara/poltergeist'
require 'capybara/rspec'
require 'capybara/rails'
require 'equivalent-xml'
require 'equivalent-xml/rspec_matchers'
require 'database_cleaner'
require 'support/controller_level_helpers'
require 'support/features'
require 'support/factory_helpers'
require 'support/rake'
require 'support/matchers/api_responses'
require 'support/matchers/response_matchers'
require 'support/input_support'
require 'support/speedup'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

require 'i18n/debug' if ENV['I18N_DEBUG']
require 'byebug' unless ENV['TRAVIS']

Capybara.default_driver = :rack_test      # This is a faster driver
Capybara.javascript_driver = :poltergeist # This is slower
Capybara.default_max_wait_time = ENV['TRAVIS'] ? 30 : 15
# Adding the below to deal with random Capybara-related timeouts in CI.
# Found in this thread: https://github.com/teampoltergeist/poltergeist/issues/375
poltergeist_options = {
  js_errors: true,
  timeout: 30,
  logger: nil,
  phantomjs_logger: StringIO.new,
  phantomjs_options: [
    '--load-images=no',
    '--ignore-ssl-errors=yes'
  ]
}
Capybara.register_driver(:poltergeist) do |app|
  Capybara::Poltergeist::Driver.new(app, poltergeist_options)
end

ActiveJob::Base.queue_adapter = :inline

# require 'http_logger'
# HttpLogger.logger = Logger.new(STDOUT)
# HttpLogger.ignore = [/localhost:8983\/solr/]
# HttpLogger.colorize = false

if ENV['TRAVIS']
  # Monkey-patches the FITS runner to return the PDF FITS fixture
  module Hydra::Works
    class CharacterizationService
      def self.run(_, _)
        raise "FITS!!!"
        # return unless file_set.original_file.has_content?
        # filename = ::File.expand_path("../fixtures/pdf_fits.xml", __FILE__)
        # file_set.characterization.ng_xml = ::File.read(filename)
      end
    end
  end
end

if defined?(ClamAV)
  ClamAV.instance.loaddb
else
  class ClamAV
    include Singleton
    def scanfile(_f)
      0
    end

    def loaddb
      nil
    end
  end
end

class JsonStrategy
  def initialize
    @strategy = FactoryGirl.strategy_by_name(:create).new
  end

  delegate :association, to: :@strategy

  def result(evaluation)
    @strategy.result(evaluation).to_json
  end
end

FactoryGirl.register_strategy(:json, JsonStrategy)
FactoryGirl.definition_file_paths = [File.expand_path("../factories", __FILE__)]
FactoryGirl.find_definitions

module EngineRoutes
  def self.included(base)
    base.routes { Hyrax::Engine.routes }
  end

  def main_app
    Rails.application.class.routes.url_helpers
  end
end

require 'shoulda/matchers'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
  end
end

require 'active_fedora/cleaner'
RSpec.configure do |config|
  include ActiveFedora::Noid::RSpec

  config.include Shoulda::Matchers::ActiveRecord, type: :model

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = File.expand_path("../fixtures", __FILE__)

  config.use_transactional_fixtures = false

  config.before :suite do
    DatabaseCleaner.clean_with(:truncation)
    disable_production_minter!
  end

  config.after :suite do
    enable_production_minter!
  end

  config.before :each do |example|
    unless example.metadata[:type] == :view || example.metadata[:no_clean]
      ActiveFedora::Cleaner.clean!
    end
  end

  config.before :each do |example|
    if example.metadata[:type] == :feature && Capybara.current_driver != :rack_test
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
    end
  end

  config.include(ControllerLevelHelpers, type: :view)
  config.before(:each, type: :view) { initialize_controller_helpers(view) }

  config.before(:all, type: :feature) do
    # Assets take a long time to compile. This causes two problems:
    # 1) the profile will show the first feature test taking much longer than it
    #    normally would.
    # 2) The first feature test will trigger rack-timeout
    #
    # Precompile the assets to prevent these issues.
    visit "/assets/application.css"
    visit "/assets/application.js"
  end

  config.after do
    DatabaseCleaner.clean
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.include Shoulda::Matchers::Independent

  if Devise::VERSION >= '4.2'
    config.include Devise::Test::ControllerHelpers, type: :controller
  else
    config.include Devise::TestHelpers, type: :controller
  end

  config.include EngineRoutes, type: :controller
  config.include Warden::Test::Helpers, type: :feature
  config.after(:each, type: :feature) do
    Warden.test_reset!
    Capybara.reset_sessions!
    page.driver.reset!
  end

  config.include Capybara::RSpecMatchers, type: :input
  config.include InputSupport, type: :input
  config.include FactoryGirl::Syntax::Methods

  config.infer_spec_type_from_file_location!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.profile_examples = 10
end

# frozen_string_literal: true
ENV["RAILS_ENV"] ||= 'test'
require "bundler/setup"

def ci_build?
  ENV['CI']
end

require 'simplecov'
SimpleCov.root(File.expand_path('../..', __FILE__))

SimpleCov.start('rails') do
  add_filter '/.internal_test_app'
  add_filter '/lib/generators'
  add_filter '/spec'
  add_filter '/tasks'
  add_filter '/lib/hyrax/version.rb'
  add_filter '/lib/hyrax/engine.rb'
end

require 'factory_bot'
require 'engine_cart'
EngineCart.load_application!

require 'devise'
require 'devise/version'
require 'mida'
require 'rails-controller-testing'
require 'rspec/rails'
require 'rspec/its'
require 'rspec/matchers'
require 'rspec/active_model/mocks'
require 'capybara/rspec'
require 'capybara/rails'
require 'selenium-webdriver'
require 'webdrivers'
require 'equivalent-xml'
require 'equivalent-xml/rspec_matchers'
require 'database_cleaner'

# rubocop:disable Lint/Void
# ensure Hyrax::Schema gets loaded is resolvable for `support/` models
Hyrax::Schema
# rubocop:enable Lint/Void

# Require supporting ruby files from spec/support/ and subdirectories.  Note: engine, not Rails.root context.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true, allow: 'chromedriver.storage.googleapis.com')

require 'i18n/debug' if ENV['I18N_DEBUG']
require 'byebug' unless ci_build?

# @note In January 2018, TravisCI disabled Chrome sandboxing in its Linux
#       container build environments to mitigate Meltdown/Spectre
#       vulnerabilities, at which point Hyrax could no longer use the
#       Capybara-provided :selenium_chrome_headless driver (which does not
#       include the `--no-sandbox` argument).
Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--disable-gpu'
  browser_options.args << '--no-sandbox'
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

Capybara.default_driver = :rack_test # This is a faster driver
Capybara.javascript_driver = :selenium_chrome_headless_sandboxless # This is slower

# FIXME: Pin to older version of chromedriver to avoid issue with clicking non-visible elements
Webdrivers::Chromedriver.version = '72.0.3626.69'

# require 'http_logger'
# HttpLogger.logger = Logger.new(STDOUT)
# HttpLogger.ignore = [/localhost:8983\/solr/]
# HttpLogger.colorize = false

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
    @strategy = FactoryBot.strategy_by_name(:create).new
  end

  delegate :association, to: :@strategy

  def result(evaluation)
    @strategy.result(evaluation).to_json
  end
end

require 'hyrax/specs/shared_specs/factories/strategies/valkyrie_resource'
FactoryBot.register_strategy(:valkyrie_create, ValkyrieCreateStrategy)
FactoryBot.register_strategy(:create_using_test_adapter, ValkyrieTestAdapterCreateStrategy)
FactoryBot.register_strategy(:json, JsonStrategy)
FactoryBot.definition_file_paths = [File.expand_path("../factories", __FILE__)]
FactoryBot.find_definitions

module EngineRoutes
  def self.included(base)
    base.routes { Hyrax::Engine.routes }
  end

  def main_app
    Rails.application.class.routes.url_helpers
  end
end

require 'shoulda/matchers'
require 'shoulda/callback/matchers'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

query_registration_target =
  Valkyrie::MetadataAdapter.find(:test_adapter).query_service.custom_queries
[Hyrax::CustomQueries::Navigators::CollectionMembers,
 Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
 Hyrax::CustomQueries::FindAccessControl,
 Hyrax::CustomQueries::FindManyByAlternateIds,
 Hyrax::CustomQueries::FindFileMetadata,
 Hyrax::CustomQueries::Navigators::FindFiles].each do |handler|
  query_registration_target.register_query_handler(handler)
end

ActiveJob::Base.queue_adapter = :test

require 'active_fedora/cleaner'
RSpec.configure do |config|
  config.disable_monkey_patching!
  config.include Shoulda::Matchers::ActiveRecord, type: :model
  config.include Shoulda::Matchers::ActiveModel, type: :form
  config.include Shoulda::Callback::Matchers::ActiveModel
  config.include Hyrax::Matchers
  config.full_backtrace = true if ci_build?
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = File.expand_path("../fixtures", __FILE__)

  config.use_transactional_fixtures = false

  config.before :suite do
    DatabaseCleaner.clean_with(:truncation)
    # Noid minting causes extra LDP requests which slow the test suite.
    Hyrax.config.enable_noids = false
  end

  config.before do |example|
    if example.metadata[:type] == :feature && Capybara.current_driver != :rack_test
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
    end

    # using :workflow is preferable to :clean_repo, use the former if possible
    # It's important that this comes after DatabaseCleaner.start
    ensure_deposit_available_for(user) if example.metadata[:workflow]
    if example.metadata[:clean_repo]
      ActiveFedora::Cleaner.clean!
      # The JS is executed in a different thread, so that other thread
      # may think the root path has already been created:
      ActiveFedora.fedora.connection.send(:init_base_path) if example.metadata[:js]
    end
    Hyrax.config.nested_relationship_reindexer = if example.metadata[:with_nested_reindexing]
                                                   # Use the default relationship reindexer (and the cascading reindexing of child documents)
                                                   Hyrax.config.default_nested_relationship_reindexer
                                                 else
                                                   # Don't use the nested relationship reindexer. This slows everything down quite a bit.
                                                   ->(id:, extent:) {}
                                                 end
  end

  config.include(ControllerLevelHelpers, type: :view)

  config.before(:each, type: :view) do
    initialize_controller_helpers(view)
    WebMock.disable_net_connect!(allow_localhost: false, allow: 'chromedriver.storage.googleapis.com')

    allow(Hyrax)
      .to receive(:metadata_adapter)
      .and_return(Valkyrie::MetadataAdapter.find(:test_adapter))
  end

  config.after(:each, type: :view) do
    WebMock.disable_net_connect!(allow_localhost: true, allow: 'chromedriver.storage.googleapis.com')
  end

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
  config.include Warden::Test::Helpers, type: :request
  config.include Warden::Test::Helpers, type: :feature
  config.after(:each, type: :feature) do
    Warden.test_reset!
    Capybara.reset_sessions!
    page.driver.reset!
  end

  config.include Capybara::RSpecMatchers, type: :input
  config.include InputSupport, type: :input
  config.include FactoryBot::Syntax::Methods
  config.include OptionalExample

  config.infer_spec_type_from_file_location!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.formatter = 'LoggingFormatter'
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.profile_examples = 10

  # Use this example metadata when you want to perform jobs inline during testing.
  #
  #   describe '#my_method`, :perform_enqueued do
  #     ...
  #   end
  #
  # If you pass an `Array` of job classes, they will be treated as the filter list.
  #
  #   describe '#my_method`, perform_enqueued: [MyJobClass] do
  #     ...
  #   end
  #
  # Limit to specific job classes with:
  #
  #   ActiveJob::Base.queue_adapter.filter = [JobClass]
  #
  config.around(:example, :perform_enqueued) do |example|
    ActiveJob::Base.queue_adapter.filter =
      example.metadata[:perform_enqueued].try(:to_a)
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs    = true
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true

    example.run

    ActiveJob::Base.queue_adapter.filter = nil
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs    = false
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false
  end

  # Ensuring we have a clear queue between each spec. This appears to
  # resolve a "flappy spec" problem (found in seed 2816 for
  # SHA da3b4632b45a8bf22100f691612d299a0ac79448 of the code base)
  config.after do
    ActiveJob::Base.queue_adapter.enqueued_jobs  = []
    ActiveJob::Base.queue_adapter.performed_jobs = []
  end

  config.before(:example, :valkyrie_adapter) do |example|
    adapter_name = example.metadata[:valkyrie_adapter]

    allow(Hyrax)
      .to receive(:metadata_adapter)
      .and_return(Valkyrie::MetadataAdapter.find(adapter_name))
  end
end

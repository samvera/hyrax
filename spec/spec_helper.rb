if ENV['CI'] || ENV['COVERAGE']
  require 'coveralls'
  Coveralls.wear!
end

ENV['RAILS_ENV'] ||= 'test'

require 'factory_girl'
require 'database_cleaner'
require 'engine_cart'
EngineCart.load_application!
require 'devise'
require 'mida'

require 'rspec/matchers'
require 'shoulda/matchers'
require 'equivalent-xml/rspec_matchers'
require 'rspec/its'
require 'rspec/rails'
require 'rspec/active_model/mocks'
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
Capybara.default_max_wait_time = ENV['TRAVIS'] ? 30 : 15
require 'capybara/rspec'
require 'capybara/rails'
require 'webmock/rspec'
WebMock.allow_net_connect!

$in_travis = !ENV['TRAVIS'].nil? && ENV['TRAVIS'] == 'true'

if ENV['COVERAGE'] || $in_travis
  require 'simplecov'

  SimpleCov.root(File.expand_path('../..', __FILE__))
  SimpleCov.formatters = $in_travis ? Coveralls::SimpleCov::Formatter : SimpleCov::Formatter::HTMLFormatter
  SimpleCov.start('rails') do
    add_filter '/spec'
    add_filter '/lib/generators/curation_concerns'
    add_filter '/.internal_test_app'
  end
  SimpleCov.command_name('spec')
end

require 'curation_concerns'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }
require File.expand_path('../matchers', __FILE__)

FactoryGirl.definition_file_paths = [File.expand_path('../factories', __FILE__)]
FactoryGirl.find_definitions

require 'active_fedora/cleaner'
RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.fixture_path = File.expand_path('../fixtures', __FILE__)

  config.before :each do
    DatabaseCleaner.strategy = if Capybara.current_driver == :rack_test
                                 :transaction
                               else
                                 :truncation
                               end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.before :each do |example|
    unless example.metadata[:type] == :view || example.metadata[:no_clean]
      ActiveFedora::Cleaner.clean!
    end

    # This is a speedup for workflow specs.  If we don't have this, it will import the
    # full workflow configuration files from config/workflows/*
    FactoryGirl.create(:workflow_action) if example.metadata[:workflow]
  end

  config.include FactoryGirl::Syntax::Methods
  config.include Shoulda::Matchers::Independent

  if defined? Devise::Test::ControllerHelpers
    config.include Devise::Test::ControllerHelpers, type: :controller
    config.include Devise::Test::ControllerHelpers, type: :view
  else
    config.include Devise::TestHelpers, type: :controller
    config.include Devise::TestHelpers, type: :view
  end

  config.include TestViewHelpers, type: :view
  config.include Capybara::DSL, type: :view

  config.include Warden::Test::Helpers, type: :feature
  config.after(:each, type: :feature) { Warden.test_reset! }

  config.include(ControllerLevelHelpers, type: :helper)
  config.before(:each, type: :helper) { initialize_controller_helpers(helper) }

  config.include(ControllerLevelHelpers, type: :view)
  config.before(:each, type: :view) { initialize_controller_helpers(view) }

  config.include BackportTest, type: :controller unless Rails.version > '5'
  config.include Controllers::EngineHelpers, type: :controller
  config.include Controllers::EngineHelpers, type: :helper
  config.include ::Rails.application.routes.url_helpers

  config.include Rails.application.routes.url_helpers, type: :routing
  config.include InputSupport, type: :input
  config.include Capybara::RSpecMatchers, type: :input
  config.infer_spec_type_from_file_location!
  config.deprecation_stream

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = 'spec/examples.txt'
  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
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

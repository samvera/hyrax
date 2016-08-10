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
    add_filter '/lib/generators/curation_concerns/templates'
    add_filter '/lib/generators/curation_concerns/install_generator.rb'
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
  end

  config.include FactoryGirl::Syntax::Methods
  if defined? Devise::Test::ControllerHelpers
    config.include Devise::Test::ControllerHelpers, type: :controller
    config.include Devise::Test::ControllerHelpers, type: :view
  else
    config.include Devise::TestHelpers, type: :controller
    config.include Devise::TestHelpers, type: :view
  end
  config.include Warden::Test::Helpers, type: :feature
  config.after(:each, type: :feature) { Warden.test_reset! }
  config.include Controllers::EngineHelpers, type: :controller
  config.include Rails.application.routes.url_helpers, type: :routing
  config.include Capybara::DSL
  config.include InputSupport, type: :input
  config.include Capybara::RSpecMatchers, type: :input
  config.infer_spec_type_from_file_location!
  config.deprecation_stream
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

require 'coveralls'
Coveralls.wear!

ENV['RAILS_ENV'] ||= 'test'

require 'factory_girl'
require 'database_cleaner'
require 'engine_cart'
EngineCart.load_application!
require 'devise'

require 'rspec/its'
require 'rspec/rails'
require 'rspec/active_model/mocks'
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = ENV['TRAVIS'] ? 30 : 15
require 'capybara/rspec'
require 'capybara/rails'

$in_travis = !ENV['TRAVIS'].nil? && ENV['TRAVIS'] == 'true'

if ENV['COVERAGE'] || $in_travis
  require 'simplecov'

  SimpleCov.root(File.expand_path('../..', __FILE__))
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start('rails') do
    add_filter '/spec'
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

  config.before :each do |example|
    unless example.metadata[:type] == :view || example.metadata[:no_clean]
      ActiveFedora::Cleaner.clean!
    end
  end

  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, type: :controller
  config.include Devise::TestHelpers, type: :view
  config.include Warden::Test::Helpers, type: :feature
  config.after(:each, type: :feature) { Warden.test_reset! }
  config.include Controllers::EngineHelpers, type: :controller
  config.include Rails.application.routes.url_helpers, type: :routing
  config.include Capybara::DSL
  config.infer_spec_type_from_file_location!
  config.deprecation_stream
end

module FactoryGirl
  def self.find_or_create(handle, by = :email)
    tmpl = FactoryGirl.build(handle)
    tmpl.class.send("find_by_#{by}".to_sym, tmpl.send(by)) || FactoryGirl.create(handle)
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

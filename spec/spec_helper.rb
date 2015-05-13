ENV["RAILS_ENV"] ||= 'test'

require 'factory_girl'
require 'database_cleaner'
require 'engine_cart'
EngineCart.load_application!
require 'devise'

require 'rspec/its'
require 'rspec/rails'
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = ENV['TRAVIS'] ? 30 : 15
require 'capybara/rspec'
require 'capybara/rails'


if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'
  require 'coveralls'

  ENGINE_ROOT = File.expand_path('../..', __FILE__)
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter if ENV["CI"]
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'worthwhile'

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}
require File.expand_path('../matchers', __FILE__)

FactoryGirl.definition_file_paths = [File.expand_path("../factories", __FILE__)]
FactoryGirl.find_definitions

require 'active_fedora/cleaner'
RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.fixture_path = File.expand_path("../fixtures", __FILE__)

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
    unless (example.metadata[:type] == :view || example.metadata[:no_clean])
      ActiveFedora::Cleaner.clean!
    end
  end

  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, type: :controller
  config.include Devise::TestHelpers, type: :view
  config.include Warden::Test::Helpers, type: :feature
  config.after(:each, type: :feature) { Warden.test_reset! }
  config.include Controllers::EngineHelpers, type: :controller
  config.include Capybara::DSL
  config.infer_spec_type_from_file_location!
  config.deprecation_stream
end

## Helper from sufia
module FactoryGirl
  def self.find_or_create(handle, by = :email)
    tmpl = FactoryGirl.build(handle)
    tmpl.class.send("find_by_#{by}".to_sym, tmpl.send(by)) || FactoryGirl.create(handle)
  end
end

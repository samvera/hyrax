ENV["RAILS_ENV"] ||= 'test'

require 'factory_girl'
require 'database_cleaner'
require 'devise'
require 'engine_cart'
EngineCart.load_application!

require 'rspec/rails'
require 'rspec/autorun'
# require 'capybara/poltergeist'
# Capybara.javascript_driver = :poltergeist
# Capybara.default_wait_time = 5

require 'worthwhile'


Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

FactoryGirl.definition_file_paths = [File.expand_path("../factories", __FILE__)]
FactoryGirl.find_definitions


RSpec.configure do |config|
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

  config.include Devise::TestHelpers, type: :controller
  config.include Devise::TestHelpers, type: :view
  config.include Warden::Test::Helpers, type: :feature
  config.after(:each, type: :feature) { Warden.test_reset! }
  config.include Controllers::EngineHelpers, type: :controller
  config.include Capybara::DSL
end

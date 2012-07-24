# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

#require 'capybara/rspec'
#require 'capybara/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  config.mock_with :mocha

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.include Devise::TestHelpers, :type => :controller

  # recipe borrowed from Redis wiki
  # REDIS_PID = "#{Rails.root}/tmp/pids/redis-test.pid"
  # REDIS_CACHE_PATH = "#{Rails.root}/tmp/cache"

  # config.before(:suite) do
  #   redis_options = {
  #     'daemonize' => 'yes',
  #     'pidfile' => REDIS_PID,
  #     'port' => 9736,
  #     'timeout' => 300,
  #     'save 900' => 1,
  #     'save 300' => 1,
  #     'save 60' => 10000,
  #     'dbfilename' => REDIS_CACHE_PATH,
  #     'loglevel' => 'debug',
  #     'logfile' => 'stdout',
  #     'databases' => 16
  #   }.map{ |k, v| "#{k} #{v}" }.join("\n")
  #   %x{ echo "#{redis_options}" | redis-server - }
  # end

  # config.after(:suite) do
  #   %x{
  #     cat "#{REDIS_PID}" | xargs kill -QUIT
  #     rm -f #{REDIS_CACHE_PATH}/dump.rdb
  #   }
  # end
end

module FactoryGirl
  def self.find_or_create(handle, by=:login)
    tmpl = FactoryGirl.build(handle)
    tmpl.class.send("find_by_#{by}".to_sym, tmpl.send(by)) || FactoryGirl.create(handle)
  end
end

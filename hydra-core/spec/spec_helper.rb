ENV["RAILS_ENV"] ||= "test"

require 'engine_cart'
path = File.expand_path(File.join('..', '..', '..', '.internal_test_app'), __FILE__)
EngineCart.load_application! path

require 'bundler/setup'
require 'rspec/rails'
require 'hydra-core'
require "factory_girl"
require "factories"

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end

ActiveFedora::Base.logger = Logger.new(STDOUT)

require 'active_fedora/cleaner'
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!

  config.before(:each) do
    ActiveFedora::Cleaner.clean!
  end
end

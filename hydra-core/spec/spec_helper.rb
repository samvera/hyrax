$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("config/environment", ENV['RAILS_ROOT'] || File.expand_path("../internal", __FILE__))
require 'bundler/setup'
require 'rspec/rails'
require 'hydra-core'

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end

ActiveFedora::Base.logger = Logger.new(STDOUT)

require 'active_fedora/cleaner'
RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!

  config.before(:each) do
    ActiveFedora::Cleaner.clean!
  end
end

# -*- encoding : utf-8 -*-
# This file is copied to spec/ when you run 'rails generate rspec:install'
# Has been customized by Blacklight to work when application is in one place,
# and actual spec/ stuff is in another (the blacklight gem checkout).  

ENV["RAILS_ENV"] ||= 'test'


if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start do
    add_filter "/test_support/"
    add_filter "/tmp/"

    add_filter do |source_file|
      source_file.lines.count < 5
    end
  end
end

#require File.expand_path("../../config/environment", __FILE__)
# version that works with our blacklight:spec stuff that calls specs
# in a remote directory. 
require File.expand_path("config/environment", ENV['RAILS_ROOT'] || File.expand_path("../../../tmp/test_app", __FILE__))
require 'rspec/rails'

require File.expand_path(File.dirname(__FILE__) +'/factories')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
# Blacklight, again, make sure we're looking in the right place for em. 
# Relative to HERE, NOT to Rails.root, which is off somewhere else. 
#Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
Dir[Pathname.new(File.expand_path("../support/**/*.rb", __FILE__))].each {|f| require f}


RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  config.mock_with :mocha

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = File.expand_path(File.dirname(__FILE__) + '/../fixtures')

  config.include Devise::TestHelpers, :type => :controller

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
  config.color_enabled = true

end

def fixture(file)
  File.new(File.join(File.dirname(__FILE__),'..', 'fixtures', file))
end


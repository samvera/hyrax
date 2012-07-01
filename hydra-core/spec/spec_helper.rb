$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))


require File.expand_path("config/environment", ENV['RAILS_ROOT'] || File.expand_path("../internal", __FILE__))
require 'rspec/rails'
require 'rspec/autorun'
require 'hydra-core'


if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end

RSpec.configure do |config|

end



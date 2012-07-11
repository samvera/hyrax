ENV["environment"] ||= "test"
module Hydra
  # Stubbing Hydra.config[:policy_aware] so Hydra::PolicyAwareAbility will be loaded for tests.
  def self.config
    {:permissions=>{:policy_aware => true}}
  end
end


$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))



if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end

require 'rspec/autorun'
require 'hydra-access-controls'
require 'support/mods_asset'
require 'support/solr_document'
require "support/user"
require "factory_girl"
require "factories"

require 'support/blacklight'
require 'support/rails'

RSpec.configure do |config|

end

# Stubbing a deprecated class/method so it won't mess up tests.
class Hydra::SuperuserAttributes
 cattr_accessor :silenced
end

# Stubbing Devise
class Devise
  def self.authentication_keys
    ["uid"]
  end
end

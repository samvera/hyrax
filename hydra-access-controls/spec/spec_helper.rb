ENV["environment"] ||= "test"

require 'rspec/mocks'
require 'rspec/its'
require 'hydra-access-controls'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
Hydra::Engine.config.autoload_paths.each { |path| $LOAD_PATH.unshift path }

if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end


require 'support/rails'

# Since we're not doing a Rails Engine test, we have to load these classes manually:
require 'active_support'
require 'active_support/dependencies'
relative_load_paths = ["#{Blacklight.root}/app/controllers/concerns",
                       "#{Blacklight.root}/app/models",
                       "app/models",
                       "app/models/concerns",
                       "app/indexers",
                       "app/services",
                       "app/validators",
                       "app/vocabularies"]
ActiveSupport::Dependencies.autoload_paths += relative_load_paths

require 'support/mods_asset'
require 'support/solr_document'
require "support/user"
require "factory_girl"
require "factories"


RSpec.configure do |config|

end

# Stubbing Devise
class Devise
  def self.authentication_keys
    ["uid"]
  end
end

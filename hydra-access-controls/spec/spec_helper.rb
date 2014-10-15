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
require_relative '../app/vocabularies/acl'
require_relative '../app/vocabularies/hydra/acl'
require_relative '../app/models/role_mapper'
require_relative '../app/models/ability'
require_relative '../app/models/hydra/access_controls/access_control_list'
require_relative '../app/models/hydra/access_controls/permission'
require_relative '../app/models/hydra/access_controls/embargo'
require_relative '../app/models/hydra/access_controls/lease'
require_relative '../app/services/hydra/lease_service'
require_relative '../app/services/hydra/embargo_service'
require_relative '../app/validators/hydra/future_date_validator'
require 'support/mods_asset'
require 'support/solr_document'
require "support/user"
require "factory_girl"
require "factories"

# HttpLogger.logger = Logger.new(STDOUT)
# HttpLogger.ignore = [/localhost:8983\/fedora/]
# HttpLogger.colorize = false

RSpec.configure do |config|
  config.before(:each) do
    begin
      ActiveFedora.fedora.connection.delete(ActiveFedora.fedora.base_path.sub('/', ''))
    rescue StandardError
    end
    ActiveFedora.fedora.connection.put(ActiveFedora.fedora.base_path.sub('/', ''),"")
  end
end

# Stubbing Devise
class Devise
  def self.authentication_keys
    ["uid"]
  end
end

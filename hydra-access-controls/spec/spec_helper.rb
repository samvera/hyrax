ENV["environment"] ||= "test"

require 'rspec/mocks'
require 'rspec/autorun'
require 'hydra-access-controls'

module Hydra
  def self.config
    indexer = Solrizer::Descriptor.new(:string, :stored, :indexed, :multivalued)
    {
      :permissions => {
        # Stubbing Hydra.config[:policy_aware] so Hydra::PolicyAwareAbility will be loaded for tests.
        :policy_aware => true,
        :discover => {
          :group => ActiveFedora::SolrService.solr_name("discover_access_group", indexer), 
          :individual => ActiveFedora::SolrService.solr_name("discover_access_person", indexer)
        },
        :read => {
          :group => ActiveFedora::SolrService.solr_name("read_access_group", indexer), 
          :individual => ActiveFedora::SolrService.solr_name("read_access_person", indexer)
        },
        :edit => {
          :group => ActiveFedora::SolrService.solr_name("edit_access_group", indexer), 
          :individual => ActiveFedora::SolrService.solr_name("edit_access_person", indexer)
        },
        :embargo_release_date => ActiveFedora::SolrService.solr_name("embargo_release_date", Solrizer::Descriptor.new(:date, :stored, :indexed)),
        
        :inheritable => {
          :discover => {
            :group => ActiveFedora::SolrService.solr_name("inheritable_discover_access_group", indexer), 
            :individual => ActiveFedora::SolrService.solr_name("inheritable_discover_access_person", indexer)
          },
          :read => {
            :group => ActiveFedora::SolrService.solr_name("inheritable_read_access_group", indexer), 
            :individual => ActiveFedora::SolrService.solr_name("inheritable_read_access_person", indexer)
          },
          :edit => {
            :group => ActiveFedora::SolrService.solr_name("inheritable_edit_access_group", indexer), 
            :individual => ActiveFedora::SolrService.solr_name("inheritable_edit_access_person", indexer)
          },
          :embargo_release_date => ActiveFedora::SolrService.solr_name("inheritable_embargo_release_date", Solrizer::Descriptor.new(:date, :stored, :indexed))
        } # inheritable
      }
    }
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
Hydra::Engine.config.autoload_paths.each { |path| $LOAD_PATH.unshift path }

if ENV['COVERAGE'] and RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end

require 'support/mods_asset'
require 'support/solr_document'
require "support/user"
require "factory_girl"
require "factories"

require 'support/blacklight'
require 'support/rails'
Object.logger = Logger.new(File.expand_path('../test.log', __FILE__))

# Since we're not doing a Rails Engine test, we have to load these classes manually:
require_relative '../app/models/role_mapper'
require_relative '../app/models/ability'



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

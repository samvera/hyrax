# The following lines determine which user attributes your hydrangea app will use
# This configuration allows you to use the out of the box ActiveRecord associations between users and user_attributes
# It also allows you to specify your own user attributes
# The easiest way to override these methods would be to create your own module to include in User
# For example you could create a module for your local LDAP instance called MyLocalLDAPUserAttributes:
#   User.send(:include, MyLocalLDAPAttributes)
# As long as your module includes methods for full_name, affiliation, and photo the personalization_helper should function correctly
#

# windows doesn't properly require hydra-head (from the gemfile), so we need to require it explicitly here:
require 'hydra/head' unless defined? Hydra

if Hydra.respond_to?(:configure)
  Hydra.configure(:shared) do |config|
    # This specifies the solr field names of permissions-related fields.
    # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
    # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
    indexer = Solrizer::Descriptor.new(:string, :stored, :indexed, :multivalued)
    config[:permissions] = {
      :discover => {:group =>ActiveFedora::SolrService.solr_name("discover_access_group", indexer), :individual=>ActiveFedora::SolrService.solr_name("discover_access_person", indexer)},
      :read => {:group =>ActiveFedora::SolrService.solr_name("read_access_group", indexer), :individual=>ActiveFedora::SolrService.solr_name("read_access_person", indexer)},
      :edit => {:group =>ActiveFedora::SolrService.solr_name("edit_access_group", indexer), :individual=>ActiveFedora::SolrService.solr_name("edit_access_person", indexer)},
      :owner => ActiveFedora::SolrService.solr_name("depositor", indexer),
      :embargo_release_date => ActiveFedora::SolrService.solr_name("embargo_release_date", Solrizer::Descriptor.new(:date, :stored, :indexed))
    }
    
  end
end

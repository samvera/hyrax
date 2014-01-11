# windows doesn't properly require hydra-head (from the gemfile), so we need to require it explicitly here:
require 'hydra/head' unless defined? Hydra

Hydra.configure do |config|
  # This specifies the solr field names of permissions-related fields.
  # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
  # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
  #
  # config.permissions.discover.group       = ActiveFedora::SolrService.solr_name("discover_access_group", :symbol)
  # config.permissions.discover.individual  = ActiveFedora::SolrService.solr_name("discover_access_person", :symbol)
  # config.permissions.read.group           = ActiveFedora::SolrService.solr_name("read_access_group", :symbol)
  # config.permissions.read.individual      = ActiveFedora::SolrService.solr_name("read_access_person", :symbol)
  # config.permissions.edit.group           = ActiveFedora::SolrService.solr_name("edit_access_group", :symbol)
  # config.permissions.edit.individual      = ActiveFedora::SolrService.solr_name("edit_access_person", :symbol)
  #
  # config.permissions.embargo_release_date = ActiveFedora::SolrService.solr_name("embargo_release_date", Solrizer::Descriptor.new(:date, :stored, :indexed))
  # }
  #
  # specify the user model
  # config.user_model = '#{model_name.classify}'
end

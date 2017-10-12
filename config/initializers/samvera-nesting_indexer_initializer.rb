# rubocop:disable Style/FileName
require 'samvera/nesting_indexer'
# rubocop:enable Style/FileName

Samvera::NestingIndexer.configure do |config|
  # How many layers of nesting are allowed for collections
  # For maximum_nesting_depth of 3 the following will raise an exception
  # C1 <- C2 <- C3 <- W1
  config.maximum_nesting_depth = 5
  config.adapter = Hyrax::Adapters::NestingIndexAdapter
  config.solr_field_name_for_storing_parent_ids = Solrizer.solr_name('nesting_collection__parent_ids', :symbol)
  config.solr_field_name_for_storing_ancestors =  Solrizer.solr_name('nesting_collection__ancestors', :symbol)
  config.solr_field_name_for_storing_pathnames =  Solrizer.solr_name('nesting_collection__pathnames', :symbol)
end

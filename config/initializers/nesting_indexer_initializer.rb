# frozen_string_literal: true

require 'samvera/nesting_indexer'
require 'hyrax/repository_reindexer'

Samvera::NestingIndexer.configure do |config|
  # How many layers of nesting are allowed for collections
  # For maximum_nesting_depth of 3 the following will raise an exception
  # C1 <- C2 <- C3 <- W1
  config.maximum_nesting_depth = 5
  config.adapter = Hyrax::Adapters::NestingIndexAdapter
  config.solr_field_name_for_storing_parent_ids = "nesting_collection__parent_ids_ssim"
  config.solr_field_name_for_storing_ancestors =  "nesting_collection__ancestors_ssim"
  config.solr_field_name_for_storing_pathnames =  "nesting_collection__pathnames_ssim"
  config.solr_field_name_for_deepest_nested_depth = 'nesting_collection__deepest_nested_depth_isi'
end

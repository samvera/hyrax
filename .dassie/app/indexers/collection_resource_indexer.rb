# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceIndexer < Hyrax::Indexers::PcdmCollectionIndexer
  include Hyrax::Indexer(:basic_metadata) if Hyrax.config.collection_include_metadata?
  check_if_flexible(CollectionResource)
end

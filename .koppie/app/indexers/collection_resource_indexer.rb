# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceIndexer < Hyrax::PcdmCollectionIndexer
  if Hyrax.config.collection_include_metadata?
    include Hyrax::Indexer(:basic_metadata)
    include Hyrax::Indexer(:collection_resource)
  end
  check_if_flexible(CollectionResource)
end

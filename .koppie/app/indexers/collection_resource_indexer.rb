# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceIndexer < Hyrax::PcdmCollectionIndexer
  include Hyrax::Indexer(:basic_metadata) unless Hyrax.config.flexible?
  include Hyrax::Indexer(:collection_resource) unless Hyrax.config.flexible?
  include Hyrax::Indexer('CollectionResource') if Hyrax.config.flexible?
end

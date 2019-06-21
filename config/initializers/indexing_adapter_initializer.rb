# frozen_string_literal: true
require 'valkyrie/indexing_adapter'
require 'valkyrie/indexing/solr/indexing_adapter'

Rails.application.config.to_prepare do
  Valkyrie::IndexingAdapter.register(
    Valkyrie::Indexing::Solr::IndexingAdapter.new(
      resource_indexer: Valkyrie::Persistence::Solr::MetadataAdapter::NullIndexer
      #      resource_indexer: Valkyrie::Persistence::Solr::CompositeIndexer.new(
      #        Hyrax::Indexers::BaseIndexer,
      #        #Hyrax::Indexers::WorkIndexer,
      #        #Hyrax::Indexers::CollectionIndexer
      # )
    ),
    :solr_index
  )
end

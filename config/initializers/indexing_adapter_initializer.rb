# frozen_string_literal: true
require 'valkyrie/indexing_adapter'
require 'valkyrie/indexing/solr/indexing_adapter'

Rails.application.config.to_prepare do
  Valkyrie::IndexingAdapter.register(
    Valkyrie::Indexing::Solr::IndexingAdapter.new(
      resource_indexer: Hyrax::ValkyrieIndexer
    ),
    :solr_index
  )
end

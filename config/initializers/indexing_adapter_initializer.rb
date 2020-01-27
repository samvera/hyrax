# frozen_string_literal: true
require 'valkyrie/indexing_adapter'
require 'valkyrie/indexing/solr/indexing_adapter'
require 'valkyrie/indexing/null_indexing_adapter'

Rails.application.config.to_prepare do
  Valkyrie::IndexingAdapter.register(
    Valkyrie::Indexing::Solr::IndexingAdapter.new,
    :solr_index
  )
  Valkyrie::IndexingAdapter.register(
    Valkyrie::Indexing::NullIndexingAdapter.new, :null_index
  )
end

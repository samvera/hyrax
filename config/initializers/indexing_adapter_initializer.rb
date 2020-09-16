# frozen_string_literal: true

Valkyrie::IndexingAdapter.register(
  Valkyrie::Indexing::Solr::IndexingAdapter.new,
  :solr_index
)
Valkyrie::IndexingAdapter.register(
  Valkyrie::Indexing::NullIndexingAdapter.new, :null_index
)

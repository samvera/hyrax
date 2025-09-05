# frozen_string_literal: true
module WithIndexing
  def with_live_indexing
    if Hyrax.config.index_adapter.is_a?(Valkyrie::Indexing::NullIndexingAdapter)
      Hyrax.config.index_adapter = :solr_index
      r = yield
      Hyrax.config.index_adapter = :null_index
      r
    else
      yield
    end
  end

  RSpec.configure do |config|
    config.include WithIndexing
  end
end

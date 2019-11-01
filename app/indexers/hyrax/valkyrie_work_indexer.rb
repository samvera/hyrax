# frozen_string_literal: true

module Hyrax
  ##
  # Indexes Hyrax::Work objects
  class ValkyrieWorkIndexer < Hyrax::ValkyrieIndexer
    Hyrax::ValkyrieIndexer.register self, as_indexer_for: Hyrax::Work

    include Hyrax::CoreMetadataIndexer
    include Hyrax::ResourceIndexer
  end
end

# frozen_string_literal: true
module Hyrax
  class CollectionWithBasicMetadataIndexer < CollectionIndexer
    include Hyrax::IndexesBasicMetadata
  end
end

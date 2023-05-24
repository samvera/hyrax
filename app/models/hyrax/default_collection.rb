# frozen_string_literal: true
module Hyrax
  class DefaultCollection < ActiveFedora::Base
    include ::Hyrax::CollectionBehavior
    # You can replace these metadata if they're not suitable
    include Hyrax::BasicMetadata
    self.indexer = Hyrax::CollectionWithBasicMetadataIndexer
  end
end

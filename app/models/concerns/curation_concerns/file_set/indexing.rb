module CurationConcerns
  module FileSet
    module Indexing
      extend ActiveSupport::Concern

      included do
        class_attribute :indexer
        # the default indexing service
        self.indexer = CurationConcerns::FileSetIndexer
      end
    end
  end
end

module CurationConcerns
  module FileSet
    module Indexing
      extend ActiveSupport::Concern

      module ClassMethods
        # override the default indexing service
        def indexer
          CurationConcerns::FileSetIndexer
        end
      end
    end
  end
end

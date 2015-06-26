module CurationConcerns
  module File
    module Indexing
      extend ActiveSupport::Concern

      module ClassMethods
        # override the default indexing service
        def indexer
          Sufia::GenericFileIndexingService
        end
      end
    end
  end
end

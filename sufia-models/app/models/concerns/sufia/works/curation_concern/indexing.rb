module Sufia::Works
  module CurationConcern
    module Indexing
      extend ActiveSupport::Concern

      module ClassMethods

        def indexer
          CurationConcerns::GenericWorkIndexingService
        end

      end

    end
  end
end

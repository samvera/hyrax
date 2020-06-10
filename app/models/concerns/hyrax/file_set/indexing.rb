# frozen_string_literal: true
module Hyrax
  class FileSet
    module Indexing
      extend ActiveSupport::Concern

      included do
        # the default indexing service
        self.indexer = Hyrax::FileSetIndexer
      end
    end
  end
end

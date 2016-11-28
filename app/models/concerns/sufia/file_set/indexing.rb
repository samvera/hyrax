module Sufia
  module FileSet
    module Indexing
      extend ActiveSupport::Concern

      included do
        class_attribute :indexer
        # the default indexing service
        self.indexer = Sufia::FileSetIndexer
      end
    end
  end
end

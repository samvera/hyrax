module Hyrax
  extend Deprecation

  class CollectionWithBasicMetadataIndexer < CollectionIndexer
    def initialize(*)
      super
      Deprecation.warn(
        self, "Hyrax::CollectionWithBasicMetadataIndexer is deprecated, "\
              "and will be removed in a future release.  "\
              "Instead, use Hyrax::CollectionIndexer."
      )
    end
  end
end

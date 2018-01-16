module Hyrax
  module IndexesLinkedMetadata
    extend ActiveSupport::Concern
    extend Deprecation

    included do
      Deprecation.warn(
        self, "Hyrax::IndexesLinkedMetadata is deprecated, "\
              "and will be removed in a future release.  "\
              "Instead, override \#rdf_service directly."
      )
    end

    # We're overriding a method from ActiveFedora::IndexingService
    def rdf_service
      DeepIndexingService
    end
  end
end

module Hyrax
  module IndexesBasicMetadata
    extend ActiveSupport::Concern
    extend Deprecation

    included do
      Deprecation.warn(
        self, "Hyrax::IndexesBasicMetadata is deprecated.  "\
              "It no longer has any effect and will be removed in a future release."
      )
    end
  end
end

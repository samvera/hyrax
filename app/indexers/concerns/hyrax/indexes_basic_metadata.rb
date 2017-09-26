module Hyrax
  module IndexesBasicMetadata
    extend Deprecation

    included do
      Deprecation.warn(
        self, "Hyrax::IndexesBasicMetadata is deprecated.  "\
              "It no longer has any effect and will be removed in a future release."
      )
    end
  end
end

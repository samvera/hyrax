# Basic metadata for all Works
# Required fields:
#   dc:title
#   dc:rights
#   dc:relation (tag/ key term)
#   dc:creator
#
#
# Optional fields:
#   dc:contributor
#   dc:coverage
#   dc:date
#   dc:description
#   dc:format
#   dc:identifier
#   dc:language
#   dc:publisher
#   dc:source
#   dc:subject
#   dc:type
module Sufia::Works
  module CurationConcern
    module WithBasicMetadata
      extend ActiveSupport::Concern

      included do
        include GenericWorkRdfProperties
      end

    end
  end
end

module Hyrax::Works
  module Metadata
    extend ActiveSupport::Concern

    included do
      attribute :arkivo_checksum, Valkyrie::Types::String
      #property :arkivo_checksum, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#arkivoChecksum'), multiple: false
    end
  end
end

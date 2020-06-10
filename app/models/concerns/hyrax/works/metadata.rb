# frozen_string_literal: true
module Hyrax::Works
  module Metadata
    extend ActiveSupport::Concern

    included do
      property :arkivo_checksum, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#arkivoChecksum'), multiple: false
    end
  end
end

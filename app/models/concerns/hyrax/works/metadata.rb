module Hyrax::Works
  # Optional metadata for Work objects
  module Metadata
    extend ActiveSupport::Concern

    included do
      attribute :arkivo_checksum, Valkyrie::Types::String
    end
  end
end

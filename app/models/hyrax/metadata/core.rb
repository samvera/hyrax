# frozen_string_literal: true

module Hyrax
  module Metadata
    class Core
      ATTRIBUTES = {
        title:         Valkyrie::Types::Array.of(Valkyrie::Types::String),
        date_modified: Valkyrie::Types::DateTime,
        date_uploaded: Valkyrie::Types::DateTime,
        depositor:     Valkyrie::Types::String
      }.freeze

      def attributes
        ATTRIBUTES
      end
    end
  end
end

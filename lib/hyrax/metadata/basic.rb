# frozen_string_literal: true

module Hyrax
  module Metadata
    ##
    # @api private
    class Basic
      ATTRIBUTES = {
        abstract:               Valkyrie::Types::Array.of(Valkyrie::Types::String),
        access_rights:           Valkyrie::Types::Array.of(Valkyrie::Types::String),
        alternative_title:      Valkyrie::Types::Array.of(Valkyrie::Types::String),
        based_near:             Valkyrie::Types::Array.of(Valkyrie::Types::String),
        contributor:            Valkyrie::Types::Array.of(Valkyrie::Types::String),
        creator:                Valkyrie::Types::Array.of(Valkyrie::Types::String),
        date_created:           Valkyrie::Types::Array.of(Valkyrie::Types::DateTime),
        description:            Valkyrie::Types::Array.of(Valkyrie::Types::String),
        bibliographic_citation: Valkyrie::Types::Array.of(Valkyrie::Types::String),
        identifier:             Valkyrie::Types::Array.of(Valkyrie::Types::String),
        import_url:             Valkyrie::Types::String,
        keyword:                Valkyrie::Types::Array.of(Valkyrie::Types::String),
        publisher:              Valkyrie::Types::Array.of(Valkyrie::Types::String),
        label:                  Valkyrie::Types::String,
        language:               Valkyrie::Types::Array.of(Valkyrie::Types::String),
        license:                Valkyrie::Types::Array.of(Valkyrie::Types::String),
        relative_path:          Valkyrie::Types::String,
        related_url:            Valkyrie::Types::Array.of(Valkyrie::Types::String),
        resource_type:          Valkyrie::Types::Array.of(Valkyrie::Types::String),
        rights_notes:           Valkyrie::Types::Array.of(Valkyrie::Types::String),
        rights_statement:       Valkyrie::Types::Array.of(Valkyrie::Types::String),
        source:                 Valkyrie::Types::Array.of(Valkyrie::Types::String),
        subject:                Valkyrie::Types::Array.of(Valkyrie::Types::String)
      }.freeze

      def attributes
        ATTRIBUTES
      end
    end
  end
end

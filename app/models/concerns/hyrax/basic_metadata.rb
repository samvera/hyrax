module Hyrax
  # An optional model mixin to define some simple properties. This must be mixed
  # after all other properties are defined because no other properties will
  # be defined once  accepts_nested_attributes_for is called
  module BasicMetadata
    extend ActiveSupport::Concern

    included do
      attribute :label, Valkyrie::Types::SingleValuedString.optional
      attribute :relative_path, Valkyrie::Types::SingleValuedString.optional
      attribute :import_url, Valkyrie::Types::SingleValuedString.optional
      attribute :resource_type, Valkyrie::Types::Set
      attribute :creator, Valkyrie::Types::Set
      attribute :contributor, Valkyrie::Types::Set
      attribute :description, Valkyrie::Types::Set

      attribute :keyword, Valkyrie::Types::Set
      # Used for a license
      attribute :license, Valkyrie::Types::Set

      # This is for the rights statement
      attribute :rights_statement, Valkyrie::Types::Set
      attribute :publisher, Valkyrie::Types::Set
      attribute :date_created, Valkyrie::Types::Set
      attribute :subject, Valkyrie::Types::Set
      attribute :language, Valkyrie::Types::Set
      attribute :identifier, Valkyrie::Types::Set
      attribute :related_url, Valkyrie::Types::Set
      # property :bibliographic_citation, predicate: ::RDF::Vocab::DC.bibliographicCitation
      attribute :source, Valkyrie::Types::Set
      attribute :based_near, Valkyrie::Types::Set
    end
  end
end

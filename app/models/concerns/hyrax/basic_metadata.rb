module Hyrax
  # An optional model mixin to define some simple properties. This must be mixed
  # after all other properties are defined because no other properties will
  # be defined once  accepts_nested_attributes_for is called
  module BasicMetadata
    extend ActiveSupport::Concern

    included do

      attribute :label, Valkyrie::Types::SingleValuedString
      # property :label, predicate: ActiveFedora::RDF::Fcrepo::Model.downloadFilename, multiple: false

      attribute :relative_path, Valkyrie::Types::SingleValuedString
      # property :relative_path, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#relativePath'), multiple: false

      # property :import_url, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#importUrl'), multiple: false
      attribute :resource_type, Valkyrie::Types::Set
      attribute :creator, Valkyrie::Types::Set
      attribute :contributor, Valkyrie::Types::Set
      attribute :description, Valkyrie::Types::Set

      # property :keyword, predicate: ::RDF::Vocab::DC11.relation
      # Used for a license
      attribute :license, Valkyrie::Types::Set

      # This is for the rights statement
      # property :rights_statement, predicate: ::RDF::Vocab::EDM.rights
      attribute :publisher, Valkyrie::Types::Set
      attribute :date_created, Valkyrie::Types::Set
      attribute :subject, Valkyrie::Types::Set
      attribute :language, Valkyrie::Types::Set
      attribute :identifier, Valkyrie::Types::Set
      # property :based_near, predicate: ::RDF::Vocab::FOAF.based_near, class_name: Hyrax::ControlledVocabularies::Location
      attribute :related_url, Valkyrie::Types::Set
      # property :bibliographic_citation, predicate: ::RDF::Vocab::DC.bibliographicCitation
      # property :source, predicate: ::RDF::Vocab::DC.source

      # id_blank = proc { |attributes| attributes[:id].blank? }
      #
      # class_attribute :controlled_properties
      # self.controlled_properties = [:based_near]
      # accepts_nested_attributes_for :based_near, reject_if: id_blank, allow_destroy: true
      attribute :based_near, Valkyrie::Types::Set
    end
  end
end

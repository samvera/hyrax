module Hyrax
  # An optional model mixin to define some simple properties. This must be mixed
  # after all other properties are defined because no other properties will
  # be defined once  accepts_nested_attributes_for is called
  module BasicMetadata
    extend ActiveSupport::Concern

    included do
      property :label, predicate: ActiveFedora::RDF::Fcrepo::Model.downloadFilename, multiple: false

      property :relative_path, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#relativePath'), multiple: false

      property :import_url, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#importUrl'), multiple: false
      property :resource_type, predicate: ::RDF::Vocab::DC.type
      property :creator, predicate: ::RDF::Vocab::DC11.creator
      property :contributor, predicate: ::RDF::Vocab::DC11.contributor
      property :description, predicate: ::RDF::Vocab::DC11.description
      property :keyword, predicate: ::RDF::Vocab::DC11.relation
      # Used for a license
      property :license, predicate: ::RDF::Vocab::DC.rights

      # This is for the rights statement
      property :rights_statement, predicate: ::RDF::Vocab::EDM.rights
      property :publisher, predicate: ::RDF::Vocab::DC11.publisher
      property :date_created, predicate: ::RDF::Vocab::DC.created
      property :subject, predicate: ::RDF::Vocab::DC11.subject
      property :language, predicate: ::RDF::Vocab::DC11.language
      property :identifier, predicate: ::RDF::Vocab::DC.identifier
      property :based_near, predicate: ::RDF::Vocab::FOAF.based_near, class_name: Hyrax::ControlledVocabularies::Location
      property :related_url, predicate: ::RDF::RDFS.seeAlso
      property :bibliographic_citation, predicate: ::RDF::Vocab::DC.bibliographicCitation
      property :source, predicate: ::RDF::Vocab::DC.source

      id_blank = proc { |attributes| attributes[:id].blank? }

      class_attribute :controlled_properties
      self.controlled_properties = [:based_near]
      accepts_nested_attributes_for :based_near, reject_if: id_blank, allow_destroy: true

      #
      # indexing functionality
      class_attribute :stored_and_facetable_fields, :stored_fields, :symbol_fields
      self.stored_and_facetable_fields = %i[resource_type creator contributor keyword publisher subject language based_near]
      self.stored_fields = %i[description license rights_statement date_created identifier related_url bibliographic_citation source]
      self.symbol_fields = %i[import_url]

      # This method is passed to {ActiveFedora::RDF::IndexingService}
      # @return [ActiveFedora::Indexing::Map]
      def self.index_config
        merge_config(
          merge_config(
            merge_config(super, stored_and_facetable_index_config),
            stored_searchable_index_config
          ),
          symbol_index_config
        )
      end

      # This can be replaced by a simple merge once
      # https://github.com/samvera/active_fedora/pull/1227
      # is available to us
      # @param [ActiveFedora::Indexing::Map] first
      # @param [Hash] second
      def self.merge_config(first, second)
        first_hash = first.instance_variable_get(:@hash).deep_dup
        ActiveFedora::Indexing::Map.new(first_hash.merge(second))
      end

      def self.stored_and_facetable_index_config
        stored_and_facetable_fields.each_with_object({}) do |name, hash|
          hash[name] = index_object_for(name, as: [:stored_searchable, :facetable])
        end
      end

      def self.stored_searchable_index_config
        stored_fields.each_with_object({}) do |name, hash|
          hash[name] = index_object_for(name, as: [:stored_searchable])
        end
      end

      def self.symbol_index_config
        symbol_fields.each_with_object({}) do |name, hash|
          hash[name] = index_object_for(name, as: [:symbol])
        end
      end

      def self.index_object_for(attribute_name, as: [])
        ActiveFedora::Indexing::Map::IndexObject.new(attribute_name) do |idx|
          idx.as(*as)
        end
      end
    end
  end
end

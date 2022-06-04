# frozen_string_literal: true
module Hyrax
  # This class gets called by ActiveFedora::IndexingService#olrize_rdf_assertions
  class BasicMetadataIndexer < ActiveFedora::RDF::IndexingService
    class_attribute :stored_and_facetable_fields, :stored_fields, :symbol_fields
    self.stored_and_facetable_fields = %i[resource_type creator contributor keyword publisher subject language based_near]
    self.stored_fields = %i[alternative_title description abstract license rights_statement rights_notes access_right date_created identifier related_url bibliographic_citation source]
    self.symbol_fields = %i[import_url]

    private

    # This method overrides ActiveFedora::RDF::IndexingService
    # @return [ActiveFedora::Indexing::Map]
    def index_config
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
    def merge_config(first, second)
      first_hash = first.instance_variable_get(:@hash).deep_dup
      ActiveFedora::Indexing::Map.new(first_hash.merge(second))
    end

    def stored_and_facetable_index_config
      stored_and_facetable_fields.index_with { |name| index_object_for(name, as: [:stored_searchable, :facetable]) }
    end

    def stored_searchable_index_config
      stored_fields.index_with { |name| index_object_for(name, as: [:stored_searchable]) }
    end

    def symbol_index_config
      symbol_fields.index_with { |name| index_object_for(name, as: [:symbol]) }
    end

    def index_object_for(attribute_name, as: [])
      ActiveFedora::Indexing::Map::IndexObject.new(attribute_name) do |idx|
        idx.as(*as)
      end
    end
  end
end

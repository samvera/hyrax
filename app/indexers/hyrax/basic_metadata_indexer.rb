module Hyrax
  class BasicMetadataIndexer < ActiveFedora::RDF::IndexingService
    class_attribute :stored_and_facetable_fields, :stored_fields
    self.stored_and_facetable_fields = %i(resource_type creator contributor keyword publisher subject language based_near)
    self.stored_fields = %i(description license rights_statement date_created identifier related_url bibliographic_citation source)

    protected

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
      # https://github.com/projecthydra/active_fedora/pull/1227
      # is available to us
      # @param [ActiveFedora::Indexing::Map] first
      # @param [Hash] second
      def merge_config(first, second)
        first_hash = first.instance_variable_get(:@hash).deep_dup
        ActiveFedora::Indexing::Map.new(first_hash.merge(second))
      end

      def stored_and_facetable_index_config
        stored_and_facetable_fields.each_with_object({}) do |name, hash|
          hash[name] = ActiveFedora::Indexing::Map::IndexObject.new(name) do |idx|
            idx.as :stored_searchable, :facetable
          end
        end
      end

      def stored_searchable_index_config
        stored_fields.each_with_object({}) do |name, hash|
          hash[name] = ActiveFedora::Indexing::Map::IndexObject.new(name) do |idx|
            idx.as :stored_searchable
          end
        end
      end

      def symbol_index_config
        { import_url: ActiveFedora::Indexing::Map::IndexObject.new(:import_url) do |idx|
          idx.as :symbol
        end }
      end
  end
end

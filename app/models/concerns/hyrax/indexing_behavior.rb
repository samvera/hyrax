module Hyrax
  # This mixin provides convenience methods for some common indexing behaviors.
  # To use them, define the following attributes on your model:
  #
  # class_attribute :stored_and_facetable_fields, :stored_fields, :symbol_fields
  # self.stored_and_facetable_fields = %i[resource_type creator contributor keyword publisher subject language based_near]
  # self.stored_fields = %i[description license rights_statement date_created identifier related_url bibliographic_citation source]
  # self.symbol_fields = %i[import_url]
  module IndexingBehavior
    extend ActiveSupport::Concern

    included do
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

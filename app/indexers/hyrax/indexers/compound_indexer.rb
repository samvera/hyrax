# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # Indexer mixin that projects compound metadata sub-properties into Solr. For
    # every compound on the resource (see {Hyrax::CompoundSchema}), it writes
    # each sub-property's declared `index_keys:`/`indexing:` Solr fields and
    # stores the displayable rows as a `<compound>_json_ss` blob the show page
    # renders from. See documentation/compound_fields.md.
    #
    # @example
    #   class WorkIndexer < Hyrax::Indexers::PcdmObjectIndexer
    #     include Hyrax::Indexers::CompoundIndexer
    #   end
    module CompoundIndexer
      def to_solr(*args)
        super.tap do |document|
          compound_schema.definitions.each do |compound_name, definition|
            next unless resource.respond_to?(compound_name)
            index_compound(document, compound_name, definition)
          end
        end
      end

      private

      def compound_schema
        @compound_schema ||= Hyrax::CompoundSchema.for(resource)
      end

      def index_compound(document, compound_name, definition)
        rows = Array(resource.public_send(compound_name))
        index_searchable_subproperties(document, definition, rows)
        index_display_blob(document, compound_name, definition, rows)
      end

      def index_searchable_subproperties(document, definition, rows)
        definition[:subproperties].each do |sub_property, spec|
          next if spec[:index_keys].blank?

          values = rows.map { |row| compound_entry_value(row, sub_property) }.reject(&:blank?)
          next if values.empty?

          spec[:index_keys].each { |index_key| document[index_key] = values }
        end
      end

      def index_display_blob(document, compound_name, definition, rows)
        display_keys = definition[:subproperties].select { |_k, spec| spec[:display] }.keys
        normalized = rows.map { |row| display_entry(row, display_keys) }.reject(&:empty?)
        document["#{compound_name}_json_ss"] = normalized.to_json unless normalized.empty?
      end

      def display_entry(row, display_keys)
        return {} unless row.respond_to?(:each_pair) || row.is_a?(::Hash)
        display_keys.each_with_object({}) do |key, memo|
          value = compound_entry_value(row, key)
          memo[key] = value if value.present?
        end
      end

      def compound_entry_value(row, sub_property)
        return nil unless row.respond_to?(:[])
        row[sub_property] || row[sub_property.to_sym]
      end
    end
  end
end

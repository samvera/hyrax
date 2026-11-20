# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # Indexer mixin that projects compound metadata sub-properties into Solr. For
    # every compound on the resource (see {Hyrax::CompoundSchema}), it writes
    # each sub-property's searchable Solr fields and stores the displayable rows
    # as a `<compound>_json_ss` blob the show page renders from. A sub-property's
    # Solr field names are *derived* — `<compound>_<name>_<suffix>` from its
    # `type:` — unless it declares an explicit `index_keys:` list (used verbatim)
    # or opts out with `indexing: false`. Deriving per-compound is what lets one
    # sub-property be reused across compounds without its fields colliding. See
    # documentation/compound_fields.md.
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
        index_searchable_subproperties(document, definition, rows, compound_name)
        index_display_blob(document, compound_name, definition, rows)
      end

      # Solr suffix set per sub-property `type:`, following the field-role
      # conventions: a `string` (open text) is both facetable (`_sim`) and
      # full-text searchable (`_tesim`), as is a `datepicker` (its ISO date is
      # text, not a `_dtsi` field); a `controlled` value is a closed vocabulary,
      # so it is facetable only (`_sim`) — full-text tokenization adds nothing
      # for fixed terms; ids/URIs get a single stored string (`_ssim`); dates a
      # date field (`_dtsi`).
      DERIVED_SUFFIXES = {
        'string' => %w[_sim _tesim],
        'datepicker' => %w[_sim _tesim],
        'controlled' => %w[_sim],
        'url' => %w[_ssim],
        'work_or_url' => %w[_ssim],
        'linked_record' => %w[_ssim],
        'id' => %w[_ssim],
        'date_time' => %w[_dtsi],
        'date' => %w[_dtsi]
      }.freeze
      DEFAULT_SUFFIXES = %w[_tesim].freeze

      def index_searchable_subproperties(document, definition, rows, compound_name)
        definition[:subproperties].each do |sub_property, spec|
          index_keys = solr_index_keys(compound_name, sub_property, spec)
          next if index_keys.empty?

          # A `multiple` member echoed back before fan-out arrives as an array;
          # flat_map indexes each term as its own facet value.
          values = rows.flat_map { |row| compound_entry_value(row, sub_property) }.reject(&:blank?)
          next if values.empty?

          index_keys.each { |index_key| document[index_key] = values }
        end
      end

      # An explicit `index_keys:` list wins; opting out (`index: false`) yields
      # none; otherwise the field names are derived from the type.
      def solr_index_keys(compound_name, sub_property, spec)
        return spec[:index_keys] if spec[:index_keys].present?
        return [] if spec[:index] == false

        suffixes = DERIVED_SUFFIXES.fetch(spec[:type].to_s, DEFAULT_SUFFIXES)
        suffixes.map { |suffix| "#{compound_name}_#{sub_property}#{suffix}" }
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

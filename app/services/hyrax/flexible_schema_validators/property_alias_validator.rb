# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    # Warns when a property declares a `name:` other than its key (an alias)
    # without a property keyed by that name, or with different Solr index keys
    # or multiplicity than that property. Show pages read a property by its
    # name, so an alias must store its values where the named property does.
    # Compound sub-properties share generic names by design and are skipped.
    class PropertyAliasValidator < BaseValidator
      def self.legacy_positional_severity
        :warning
      end

      def validate!
        properties.each do |key, config|
          name = config['name'].to_s
          next if name.empty? || name == key.to_s || subproperty?(config)

          primary = properties[name]
          next add_warning(:missing_primary, property: key, name: name) unless primary.is_a?(Hash)

          compare_with_primary(key, name, config, primary)
        end
      end

      private

      def compare_with_primary(key, name, config, primary)
        keys = index_keys(config)
        add_warning(:different_index_keys, property: key, name: name, keys: keys.join(', ')) unless keys == index_keys(primary)
        same_multiplicity = Hyrax::FlexibleSchema.multiple_values?(config) == Hyrax::FlexibleSchema.multiple_values?(primary)
        add_warning(:different_multiplicity, property: key, name: name) unless same_multiplicity
      end

      def subproperty?(config)
        Array(config.dig('available_on', 'properties')).present?
      end

      def index_keys(config)
        (Array(config['indexing']).map(&:to_s) - Hyrax::CompoundSchema::INDEX_CONTROL_TOKENS).sort
      end
    end
  end
end

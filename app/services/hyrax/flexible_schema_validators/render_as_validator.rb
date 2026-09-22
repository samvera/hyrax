# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    # Warns when a property's `view: { render_as: ... }` needs indexing the
    # property does not declare, or conflicts with the vocabulary behind it.
    #
    # Each `render_as` builds its own link, and each depends on a different
    # indexed field:
    #
    # * `linked` searches `<name>_tesim` for the *displayed* value
    # * `faceted` filters `<name>_sim` on the *stored* value
    #
    # Neither raises when the field is absent; the link simply returns nothing.
    class RenderAsValidator
      def initialize(profile, warnings)
        @profile = profile
        @warnings = warnings
      end

      def validate!
        (@profile['properties'] || {}).each do |name, config|
          next unless config.is_a?(Hash)

          view = config['view']
          next unless view.is_a?(Hash)

          case view['render_as'].to_s
          when 'linked' then validate_linked(name, config)
          when 'faceted' then validate_faceted(name, config)
          end
        end
      end

      private

      def validate_linked(name, config)
        return warn(name, :requires_searchable) unless indexes?(config, name, 'tesim')

        return unless controlled?(config)

        warn(name, facetable?(config) ? :discards_facet_link : :searches_label_for_id)
      end

      def validate_faceted(name, config)
        warn(name, :requires_facetable) unless indexes?(config, name, 'sim')
      end

      def warn(property, key)
        @warnings << I18n.t("hyrax.flexible_schema_validators.render_as_validator.warnings.#{key}", property:)
      end

      # The indexed field is named for the attribute the property stands in for,
      # which a `name:` surrogate may redirect away from the profile's own key.
      def indexes?(config, name, suffix)
        Array(config['indexing']).include?("#{config['name'].presence || name}_#{suffix}")
      end

      # Mirrors `SchemaLoader::AttributeDefinition#authority_source`: the string
      # "null" is how a profile spells "no authority", so it does not count.
      def controlled?(config)
        sources = config['controlled_values']
        return false unless sources.is_a?(Hash)

        Array(sources['sources'])
          .map { |source| source.to_s.strip }
          .any? { |source| source.present? && !source.casecmp('null').zero? }
      end

      def facetable?(config)
        Array(config['indexing']).include?('facetable')
      end
    end
  end
end

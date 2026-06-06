# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # Validates compound metadata properties (a `type: hash` property declaring
    # `subproperties:` — see {Hyrax::CompoundSchema}) in an m3 profile at save
    # time, so a misconfiguration fails with a clear message instead of producing
    # dead Solr fields or unrenderable values. See
    # documentation/forms/compound_fields.md for the rules.
    class CompoundValidator
      ##
      # @param profile [Hash] the flexible metadata profile
      # @param errors [Array<String>] an array to append errors to
      def initialize(profile:, errors:)
        @profile = profile
        @errors = errors
      end

      # @return [void]
      def validate!
        compound_properties.each do |name, config|
          validate_subproperties(name, config['subproperties'])
          validate_no_top_level_indexing(name, config)
        end
      end

      private

      # Compounds are detected by `subproperties:` presence (not `type`), so
      # other hash fields like redirects stay out of scope.
      def compound_properties
        (@profile&.dig('properties') || {}).select do |_name, config|
          config.is_a?(Hash) && config['subproperties'].present?
        end
      end

      def validate_subproperties(name, subproperties)
        unless subproperties.is_a?(Hash)
          @errors << t('subproperties_not_hash', property: name)
          return
        end

        subproperties.each { |sub_name, sub_config| validate_subproperty(name, sub_name, sub_config) }
      end

      def validate_subproperty(name, sub_name, sub_config)
        unless sub_config.is_a?(Hash)
          @errors << t('subproperty_not_hash', property: name, subproperty: sub_name, actual: sub_config.class.to_s)
          return
        end

        return unless sub_config['type'].to_s == 'controlled'
        return if sub_config['authority'].present? || sub_config['values'].present?

        @errors << t('controlled_without_source', property: name, subproperty: sub_name)
      end

      # A top-level `indexing:` would point the catalog at a `<compound>_tesim`
      # field the indexer never writes; indexing is per sub-property.
      def validate_no_top_level_indexing(name, config)
        return if config['indexing'].blank?
        @errors << t('top_level_indexing', property: name)
      end

      def t(key, **opts)
        I18n.t("hyrax.flexible_schema_validators.compound_validator.errors.#{key}", **opts)
      end
    end
  end
end

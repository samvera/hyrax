# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # Validates compound metadata in an m3 profile at save time, so a
    # misconfiguration fails with a clear message instead of producing dead Solr
    # fields or unrenderable values. A compound is a `type: hash` parent with
    # members declared as separate properties pointing back via
    # `subproperty_of: <parent>` — see {Hyrax::CompoundSchema}. See
    # documentation/compound_fields.md for the rules.
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
        subproperties.each { |name, config| validate_subproperty(name, config) }
        compound_parents.each { |name, config| validate_no_top_level_indexing(name, config) }
      end

      private

      def properties
        @properties ||= (@profile&.dig('properties') || {})
      end

      # Entries that declare `subproperty_of:` — the compound members.
      def subproperties
        properties.select { |_name, config| config.is_a?(Hash) && config['subproperty_of'].present? }
      end

      # `type: hash` parents that have at least one subproperty pointing at them.
      # (A `type: hash` with no children — e.g. redirects — is not a compound.)
      def compound_parents
        parent_names = subproperties.values.filter_map { |c| c['subproperty_of'].to_s }.to_set
        properties.select { |name, config| parent_names.include?(name.to_s) && config.is_a?(Hash) && config['type'].to_s == 'hash' }
      end

      def validate_subproperty(name, config)
        parent_name = config['subproperty_of'].to_s
        parent = properties[parent_name]
        if parent.nil? || !parent.is_a?(Hash) || parent['type'].to_s != 'hash'
          @errors << t('unknown_parent', property: name, parent: parent_name)
          return
        end

        case config['type'].to_s
        when 'controlled' then validate_controlled_source(name, config)
        when 'orcid'      then validate_orcid(name, config, parent_name)
        end
      end

      def validate_controlled_source(name, config)
        return if config['authority'].present? || config['values'].present?
        @errors << t('controlled_without_source', property: name)
      end

      # An orcid sub-property must not declare an option source (it is a
      # free-text iD, not a controlled vocabulary). Its optional `badge_for:`
      # must name a sibling sub-property on the same compound parent — not
      # itself, and not a property that lives outside the parent.
      def validate_orcid(name, config, parent_name)
        if config['authority'].present? || config['values'].present?
          @errors << t('orcid_with_option_source',
                       property: name,
                       default: "Sub-property `#{name}` declares type: orcid and must not set authority: or values:.")
        end
        validate_badge_for(name, config, parent_name)
      end

      def validate_badge_for(name, config, parent_name)
        badge_for = config['badge_for'].to_s
        return if badge_for.blank?

        if badge_for == name.to_s
          @errors << t('orcid_badge_for_self',
                       property: name,
                       default: "Sub-property `#{name}` declares badge_for: pointing at itself.")
          return
        end

        target = properties[badge_for]
        return if target.is_a?(Hash) && target['subproperty_of'].to_s == parent_name

        @errors << t('orcid_badge_for_unknown_sibling',
                     property: name, target: badge_for, parent: parent_name,
                     default: "Sub-property `#{name}` declares badge_for: `#{badge_for}`, " \
                              "which is not a sibling sub-property of `#{parent_name}`.")
      end

      # A top-level `indexing:` on a parent would point the catalog at a
      # `<compound>_tesim` field the indexer never writes; indexing is declared
      # per subproperty.
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

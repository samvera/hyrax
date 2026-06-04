# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Reads the compound metadata declarations off a resource's schema. A compound
  # is a `type: hash, multiple: true` attribute carrying a `subfields:` map; the
  # declaration drives the generic form, indexer, and renderer so a hierarchical
  # field can be defined in YAML alone. See documentation/forms/compound_fields.md.
  #
  # Declarations are read from each attribute's Dry type `meta`, which both
  # schema loaders populate identically, so the result is the same in both flex
  # modes.
  class CompoundSchema # rubocop:disable Metrics/ClassLength
    ##
    # Build a CompoundSchema for a resource instance or class.
    #
    # @param [Valkyrie::Resource, Class] resource a resource instance, or a
    #   class (used by class-level callers that only see class-declared
    #   compounds — i.e. non-flex).
    def self.for(resource)
      new(*schema_sources_for(resource))
    end

    # For a class, its own schema. For an instance, both the class schema
    # (non-flexible) and the singleton schema (flexible: the m3 attributes are
    # applied to the singleton at load time). Unioning both makes {.for} work in
    # both flex modes.
    def self.schema_sources_for(resource)
      if resource.is_a?(Class)
        [(resource.schema if resource.respond_to?(:schema))]
      else
        sources = []
        sources << resource.class.schema if resource.class.respond_to?(:schema)
        sources << resource.singleton_class.schema if resource.respond_to?(:singleton_class) && resource.singleton_class.respond_to?(:schema)
        sources
      end.compact
    end
    private_class_method :schema_sources_for

    attr_reader :schema_sources

    # @param [Array<#each>] schema_sources one or more Dry schemas (each a
    #   collection of property types responding to `name` and `meta`).
    def initialize(*schema_sources)
      @schema_sources = schema_sources.flatten.compact
    end

    ##
    # @return [Boolean] whether the given attribute is a compound (declares
    #   `subfields:`)
    def compound?(attribute_name)
      definitions.key?(attribute_name.to_sym)
    end

    ##
    # @return [Array<Symbol>] the names of every compound attribute on the
    #   resource
    def compound_names
      definitions.keys
    end

    ##
    # @return [Array<Symbol>] compounds displayed inline in the metadata list
    #   (the default)
    def inline_compound_names
      definitions.reject { |_name, d| d[:display_mode] == :card }.keys
    end

    ##
    # @return [Array<Symbol>] compounds displayed as their own card on show
    #   pages (`view: { display: card }`)
    def card_compound_names
      definitions.select { |_name, d| d[:display_mode] == :card }.keys
    end

    ##
    # @return [Boolean] whether the compound displays as a card
    def card?(attribute_name)
      definition_for(attribute_name)&.dig(:display_mode) == :card
    end

    ##
    # @param [#to_sym] attribute_name
    #
    # @return [Hash{Symbol => Object}, nil] the compound's declaration:
    #   `{ subfields:, groups:, index_subfields: }`, or nil when the attribute
    #   is not a compound.
    def definition_for(attribute_name)
      definitions[attribute_name.to_sym]
    end

    ##
    # @param [#to_sym] attribute_name
    #
    # @return [Array<String>] the ordered sub-field keys declared for the
    #   compound (empty when not a compound).
    def subfield_keys(attribute_name)
      definition = definition_for(attribute_name)
      return [] unless definition
      definition[:subfields].keys
    end

    ##
    # @return [Boolean] whether the compound itself is required (at least one
    #   row must be present to save).
    def required?(attribute_name)
      definition_for(attribute_name)&.dig(:required) || false
    end

    ##
    # @return [Array<String>] the sub-field keys declared `required: true` for
    #   the compound (each must be filled in every populated row).
    def required_subfield_keys(attribute_name)
      definition = definition_for(attribute_name)
      return [] unless definition
      definition[:subfields].select { |_key, spec| spec[:required] }.keys
    end

    ##
    # @return [Hash{Symbol => Hash}] a map from compound attribute name to its
    #   normalized declaration. Memoized per instance.
    def definitions
      @definitions ||= build_definitions
    end

    private

    def build_definitions
      schema_sources.each_with_object({}) do |schema, memo|
        next unless schema.respond_to?(:each)

        schema.each do |property|
          meta = property.respond_to?(:meta) ? property.meta : nil
          next if meta.nil?

          name = property.name.to_sym
          next if memo.key?(name)

          config = meta.with_indifferent_access
          subfields = config['subfields']
          next if subfields.blank?

          memo[name] = normalize(config, subfields)
        end
      end
    end

    # Normalizes the raw declaration into the symbol-keyed shape the form,
    # indexer, and renderer consume. See documentation/forms/compound_fields.md
    # for the meaning of each sub-field key.
    def normalize(config, subfields)
      sub = subfields.each_with_object({}) { |(key, opts), memo| memo[key.to_s] = normalize_subfield(opts) }

      view = config['view']
      display_mode = view.is_a?(Hash) && view['display'].to_s == 'card' ? :card : :inline

      { subfields: sub,
        groups: normalize_groups(config['groups'], sub.keys),
        display_mode: display_mode,
        required: compound_required?(config) }
    end

    def normalize_subfield(opts)
      opts = (opts.is_a?(Hash) ? opts : {}).with_indifferent_access
      { type: (opts['type'] || 'string').to_s,
        authority: opts['authority']&.to_s,
        values: normalize_values(opts['values']),
        index_keys: normalize_index_keys(opts),
        display: opts.fetch('display', true) != false,
        required: truthy?(opts['required']) }
    end

    # Whether the compound itself is required (at least one row must exist).
    # Reads `required: true` (non-flexible) or a minimum cardinality >= 1
    # (flexible), mirroring how M3AttributeDefinition derives requirement.
    def compound_required?(config)
      return true if truthy?(config['required'])
      cardinality = config['cardinality']
      cardinality.is_a?(Hash) && cardinality['minimum'].present? && cardinality['minimum'].to_i >= 1
    end

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value) == true
    end

    # Reads `index_keys:` (non-flexible) or `indexing:` (flexible), filtering the
    # non-field control tokens, mirroring AttributeDefinition#index_keys.
    INDEX_CONTROL_TOKENS = %w[facetable stored_searchable admin_only editor_only].freeze
    def normalize_index_keys(opts)
      raw = opts['indexing'] || opts['index_keys'] || []
      Array(raw).reject { |k| INDEX_CONTROL_TOKENS.include?(k.to_s) }.map(&:to_s)
    end

    # Normalizes an inline option list into `[[label, id], ...]`; nil when none.
    def normalize_values(values)
      return nil if values.blank?

      Array(values).map do |entry|
        if entry.is_a?(Hash)
          h = entry.with_indifferent_access
          id = (h['id'] || h['value'] || h['label']).to_s
          [(h['label'] || id).to_s, id]
        else
          [entry.to_s, entry.to_s]
        end
      end
    end

    def normalize_groups(groups, all_keys)
      return [{ label: nil, cols: 6, fields: all_keys }] if groups.blank?

      Array(groups).map do |group|
        group = group.with_indifferent_access
        { label: group['label'],
          cols: (group['cols'] || 6).to_i,
          fields: Array(group['fields']).map(&:to_s) }
      end
    end
  end
end

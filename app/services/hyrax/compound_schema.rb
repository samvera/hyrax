# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Reads the compound metadata declarations off a resource's schema. A compound
  # is a `type: hash, multiple: true` parent property; its members are declared
  # as separate properties pointing back with `subproperty_of: <parent>`. The
  # declaration drives the generic form, indexer, and renderer so a hierarchical
  # field can be defined in YAML alone. See documentation/compound_fields.md.
  #
  # The schema loaders exclude subproperties from a resource's real attributes
  # (so they get no accessor of their own) but fold each compound's members into
  # the parent's Dry type `meta` (`subproperties:`). This class reads that meta —
  # off the resource's own schema — so resolution is identical in both flex
  # modes and needs no knowledge of which schema file the resource used.
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

    ##
    # Build a CompoundSchema for a show-page Solr document. In flexible mode the
    # resource class carries no compounds (they are applied per-instance at
    # load), so resolve them from the document's indexed `schema_version`
    # without loading the resource; fall back to the model class (non-flexible).
    #
    # @param document [#hydra_model] a SolrDocument-like object
    def self.for_solr_document(document)
      new(*solr_document_schema_sources(document))
    end

    def self.solr_document_schema_sources(document)
      klass = document.hydra_model if document.respond_to?(:hydra_model)
      version = document['schema_version_ssi'] if document.respond_to?(:[])

      if klass && version.present?
        attrs = flexible_attributes_for(klass, version)
        return [attrs] if attrs.present?
      end

      schema_sources_for(klass)
    rescue StandardError => e
      Hyrax.logger.debug("CompoundSchema.for_solr_document: #{e.message}")
      []
    end
    private_class_method :solr_document_schema_sources

    # The `{ name => dry_type }` attribute map (with folded subproperties in
    # meta) for a class at a flexible schema version; nil when the loader is
    # unavailable (non-flexible installs).
    def self.flexible_attributes_for(klass, version)
      loader = Hyrax::Schema.m3_schema_loader
      loader.attributes_for(schema: klass.name, version: version, contexts: [])
    rescue StandardError
      nil
    end
    private_class_method :flexible_attributes_for

    # For a class, its own schema. For an instance, both the singleton schema
    # (flexible mode) and the class schema (non-flexible mode), so {.for} works
    # in both.
    #
    # Order is load-bearing: the singleton schema must come first so it wins
    # {#build_definitions}' first-source-per-name dedup. The class schema is
    # frozen at class-load and not refreshed when the active FlexibleSchema
    # version changes, so a flexible instance's singleton schema (rebuilt at the
    # current version) is the authoritative source for a freshly-uploaded
    # profile. In non-flexible mode the singleton has no extra schema, so order
    # is moot.
    def self.schema_sources_for(resource)
      if resource.is_a?(Class)
        [(resource.schema if resource.respond_to?(:schema))]
      else
        sources = []
        sources << resource.singleton_class.schema if resource.respond_to?(:singleton_class) && resource.singleton_class.respond_to?(:schema)
        sources << resource.class.schema if resource.class.respond_to?(:schema)
        sources
      end.compact
    end
    private_class_method :schema_sources_for

    attr_reader :schema_sources

    # @param [Array<#each>] schema_sources one or more Dry schemas (each a
    #   collection of property types responding to `name` and `meta`), or a
    #   `{ name => dry_type }` Hash (the loader's `attributes_for` output).
    def initialize(*schema_sources)
      @schema_sources = schema_sources.flatten.compact
    end

    ##
    # @return [Boolean] whether the given attribute is a compound (a `type: hash`
    #   parent with at least one subproperty)
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
    #   `{ subproperties:, groups: }`, or nil when the attribute is not a
    #   compound.
    def definition_for(attribute_name)
      definitions[attribute_name.to_sym]
    end

    ##
    # @param [#to_sym] attribute_name
    #
    # @return [Array<String>] the ordered sub-property keys declared for the
    #   compound (empty when not a compound).
    def subproperty_keys(attribute_name)
      definition = definition_for(attribute_name)
      return [] unless definition
      definition[:subproperties].keys
    end

    ##
    # @return [Boolean] whether the compound itself is required (at least one
    #   row must be present to save).
    def required?(attribute_name)
      definition_for(attribute_name)&.dig(:required) || false
    end

    ##
    # @return [Boolean] whether the compound declares `form: { primary: true }`
    #   (shown in the form's primary section rather than "Additional fields").
    def primary?(attribute_name)
      definition_for(attribute_name)&.dig(:primary) || false
    end

    ##
    # @return [Array<String>] the sub-property keys declared `required: true` for
    #   the compound (each must be filled in every populated row).
    def required_subproperty_keys(attribute_name)
      definition = definition_for(attribute_name)
      return [] unless definition
      definition[:subproperties].select { |_key, spec| spec[:required] }.keys
    end

    ##
    # @return [Hash{Symbol => Hash}] a map from compound attribute name to its
    #   normalized declaration. Memoized per instance.
    def definitions
      @definitions ||= build_definitions
    end

    private

    # Assemble one normalized definition per compound parent. A parent is an
    # attribute whose type meta carries a folded `subproperties:` map (the
    # loaders fold each compound's `subproperty_of` members into the parent's
    # meta; see {SchemaLoader#attributes_for}). A `type: hash` with no
    # subproperties (e.g. redirects) is not a compound and is skipped.
    def build_definitions
      schema_sources.each_with_object({}) do |schema, memo|
        name_meta_pairs(schema).each do |name, meta|
          next if meta.nil? || memo.key?(name)

          config = meta.with_indifferent_access
          children = config['subproperties']
          next if children.blank?

          memo[name] = normalize(config, children)
        end
      end
    end

    # `[name, meta]` pairs for a schema source, which is either a Dry schema (an
    # iterable of properties with `name`/`meta`) or a `{ name => dry_type }` Hash
    # (the loader's `attributes_for` output).
    def name_meta_pairs(schema)
      if schema.is_a?(::Hash)
        schema.map { |name, type| [name.to_sym, (type.meta if type.respond_to?(:meta))] }
      elsif schema.respond_to?(:each)
        schema.map { |property| [property.name.to_sym, (property.meta if property.respond_to?(:meta))] }
      else
        []
      end
    end

    # Normalizes a parent config plus its (folded) child configs into the
    # symbol-keyed shape the form, indexer, and renderer consume. See
    # documentation/compound_fields.md for the meaning of each key.
    def normalize(config, children)
      sub = children.each_with_object({}) { |(key, opts), memo| memo[key.to_s] = normalize_subproperty(opts) }

      view = config['view']
      display_mode = view.is_a?(Hash) && view['display'].to_s == 'card' ? :card : :inline

      { subproperties: sub,
        groups: normalize_groups(config['groups'], children),
        display_mode: display_mode,
        required: compound_required?(config),
        primary: compound_primary?(config),
        display_label: normalize_display_label(config) }
    end

    # Whether the compound declares `form: { primary: true }` (renders in the
    # form's primary section rather than "Additional fields"). Default false.
    def compound_primary?(config)
      form = config['form']
      form.is_a?(Hash) && truthy?(form['primary'])
    end

    # The declared display label as `{ locale => String }` (the m3
    # `display_label` shape), or nil when none is declared.
    def normalize_display_label(config)
      raw = config['display_label']
      return nil if raw.blank?
      raw.is_a?(Hash) ? raw.with_indifferent_access : { default: raw.to_s }.with_indifferent_access
    end

    def normalize_subproperty(opts)
      opts = (opts.is_a?(Hash) ? opts : {}).with_indifferent_access
      form = opts['form'].is_a?(Hash) ? opts['form'] : {}
      { type: (opts['type'] || 'string').to_s,
        authority: opts['authority']&.to_s,
        values: normalize_values(opts['values']),
        index_keys: normalize_index_keys(opts),
        display: opts.fetch('display', true) != false,
        required: truthy?(opts['required']),
        group: opts['group']&.to_s,
        cols: (form['cols'] || DEFAULT_COLS).to_i,
        as: form['as']&.to_s }
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

    DEFAULT_COLS = 6

    # Builds the ordered group list for a compound from its children's `group:`
    # membership and the parent's `groups:` label metadata. Groups appear in the
    # order their first member is declared (document order); a child with no
    # `group:` falls in a leading default (unlabeled) group. Field order within a
    # group is document order. `group_meta` is `{ key => { label: } }`.
    def normalize_groups(group_meta, children)
      labels = (group_meta.is_a?(Hash) ? group_meta : {}).with_indifferent_access
      ordered = {}
      children.each_key do |child_name|
        key = (children[child_name]['group'] if children[child_name].is_a?(Hash)).to_s
        (ordered[key] ||= []) << child_name.to_s
      end

      ordered.map do |key, fields|
        { key: key.presence,
          label: key.present? ? (labels.dig(key, 'label') || key.to_s.humanize) : nil,
          fields: fields }
      end
    end
  end
end

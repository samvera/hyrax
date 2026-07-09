# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # This is a simple yaml config-driven schema loader
  #
  # @see config/metadata/basic_metadata.yaml for an example configuration
  class SchemaLoader
    class UndefinedSchemaError < ArgumentError; end

    ##
    # @param [Symbol] schema
    #
    # @return [Hash<Symbol, Dry::Types::Type>] a map from attribute names to
    #   types
    def attributes_for(schema:, version: 1, contexts: nil)
      children = subproperties_by_parent(schema, version, contexts)
      definitions(schema, version, contexts).each_with_object({}) do |definition, hash|
        # Fold a compound parent's subproperties (which are excluded from the
        # real attributes) into the parent's type metadata, so the resource's
        # own schema carries them for Hyrax::CompoundSchema to read — without
        # the subproperties becoming standalone attributes.
        config = definition.config
        subs = children[definition.name.to_s]
        config = config.merge('subproperties' => subs) if subs.present?
        hash[definition.name] = definition.type.meta(config)
      end
    end

    ##
    # @param [Symbol] schema
    #
    # @return [Hash{Symbol => Hash{Symbol => Object}}]
    def form_definitions_for(schema:, version: 1, contexts: nil)
      definitions(schema, version, contexts).each_with_object({}) do |definition, hash|
        next if definition.form_options.empty?

        hash[definition.name] = definition.form_options
      end
    end

    ##
    # @param [Symbol] schema
    #
    # @return [{Symbol => Symbol}] a map from index keys to attribute names
    def index_rules_for(schema:, version: 1, contexts: nil)
      definitions(schema, version, contexts).each_with_object({}) do |definition, hash|
        definition.index_keys.each do |key|
          hash[key] = definition.name
        end
      end
    end

    ##
    # The raw per-attribute configs for a schema, INCLUDING compound
    # subproperties (entries declaring `available_on: { properties: [...] }`). Unlike
    # {#attributes_for} et al. — which exclude subproperties so they never become
    # standalone resource attributes — this returns everything declared, so
    # {Hyrax::CompoundSchema} can gather each parent compound's subproperties.
    #
    # @return [Hash{Symbol => Hash}] `{ attribute_name => raw_config_hash }`
    def raw_attribute_configs(schema:, version: 1, contexts: nil)
      raw_definitions(schema, version, contexts).each_with_object({}) do |(name, config), hash|
        hash[(config['name'] || name).to_sym] = config
      end
    end

    # @return [Boolean] whether a raw per-attribute config is a compound
    #   subproperty (declares `available_on: { properties: [...] }`, naming the
    #   parent compound(s) it belongs to), which must be excluded from the
    #   resource's real attributes.
    def subproperty_config?(config)
      config.is_a?(Hash) && subproperty_parents(config).present?
    end

    # The parent compound names a subproperty config declares membership in, via
    # `available_on: { properties: [...] }`. Empty for a non-subproperty.
    def subproperty_parents(config)
      return [] unless config.is_a?(Hash)
      Array(config.dig('available_on', 'properties')).map(&:to_s)
    end

    # Subproperty configs grouped under their parent compound, in document
    # order: `{ parent_name => { child_name => child_config } }`. A subproperty
    # may name more than one parent, so it is folded into each. The child key is
    # the subproperty's `name:` (falling back to its key), so the same field can
    # surface under a shared in-compound name (e.g. `title`) in several
    # compounds. Used to fold each compound's members into its parent's type
    # metadata (see {#attributes_for}).
    def subproperties_by_parent(schema, version, contexts)
      raw_definitions(schema, version, contexts).each_with_object({}) do |(name, config), memo|
        next unless subproperty_config?(config)

        child_name = (config['name'] || name).to_s
        subproperty_parents(config).each do |parent|
          (memo[parent] ||= {})[child_name] = config
        end
      end
    rescue StandardError => e
      Hyrax.logger.debug("subproperties_by_parent(#{schema}): #{e.message}")
      {}
    end

    def current_version
      1
    end

    ##
    # @api private
    class AttributeDefinition
      ##
      # @!attr_reader :config
      #   @return [Hash<String, Object>]
      # @!attr_reader :name
      #   @return [#to_sym]
      attr_reader :config, :name

      ##
      # @param [#to_sym] name
      # @param [Hash<String, Object>] config
      def initialize(name, config)
        @config = config
        @name   = (config['name'] || name).to_sym
      end

      ##
      # @return [Hash{Symbol => Object}]
      def form_options
        config.fetch('form', {})&.symbolize_keys || {}
      end

      ##
      # @return [Enumerable<Symbol>]
      def index_keys
        (config.fetch('indexing', nil) || config.fetch('index_keys', []))&.reject { |k| ['facetable', 'stored_searchable', 'admin_only', 'editor_only'].include?(k) }&.map(&:to_sym) || []
      end

      ##
      # @return [Hash{Symbol => Object}]
      def view_options
        # prefer display_label over view:label for labels, make available in the view
        @view_options = config.fetch('view', {})&.with_indifferent_access || {}
        Deprecation.warn('view: label is deprecated, use display_label instead') if @view_options[:label].present?
        @view_options.delete(:label)
        @view_options[:display_label] = display_label
        @view_options[:admin_only] = admin_only?
        @view_options[:editor_only] = editor_only?
        @view_options
      end

      def display_label
        return @display_label if @display_label
        @display_label = config.fetch('display_label', {})&.with_indifferent_access || {}
        @display_label = { default: @display_label } if @display_label.is_a?(String)
        @display_label
      end

      def admin_only?
        @admin_only ||= config.fetch('admin_only', false) || config['indexing']&.include?('admin_only')
      end

      def editor_only?
        @editor_only ||= config.fetch('editor_only', false) || config['indexing']&.include?('editor_only')
      end

      ##
      # @return [Dry::Types::Type]
      def type
        member_type = type_for(config['type'])
        wrapper_type = multiple? ? Valkyrie::Types::Array.constructor(&Coerce) : Identity
        wrapper_type.of(member_type)
      end

      # Cleans up the input before the type system sees it: drops the
      # "no value provided" placeholder dry-types uses internally, then
      # removes blanks. Wraps a bare Hash in a one-element array; using
      # `Array(hash)` would surprise-flatten it into [[:k, v], ...] pairs.
      # Valkyrie's JSONValueMapper unwraps single-element arrays on read,
      # so the type sees a hash here when there was originally one entry.
      Coerce = lambda do |value|
        return [] if value.equal?(Dry::Types::Undefined)
        wrapped = value.is_a?(::Hash) ? [value] : Array(value)
        wrapped.reject { |v| v.equal?(Dry::Types::Undefined) }.select(&:present?)
      end

      # Determine whether this attribute allows multiple values.
      def multiple?
        return config['multiple'] if config.key?('multiple')
        return true if config.key?('data_type') && config['data_type'] == 'array'
        return false unless (card = config['cardinality'])

        max = card['maximum']
        max.nil? || max.to_i > 1
      end

      ##
      # @api private
      #
      # Single-value wrapper that matches the multi-value branch's cleanup:
      # strips the dry-types Undefined placeholder and coerces blank strings to nil.
      # Booleans, numbers, and other types pass through unchanged.
      #
      # @example
      #   Identity.of(Valkyrie::Types::String) # => Valkyrie::Types::String with blank-string → nil coercion
      class Identity
        def self.of(type)
          type.constructor do |value|
            next nil if value.equal?(Dry::Types::Undefined)
            value.is_a?(String) ? value.presence : value
          end
        end
      end

      private

      ##
      # Resolves a `type:` value from a schema YAML to a Dry::Types::Type.
      #
      # Recognized values:
      #   - `id`, `uri`, `date_time` — Valkyrie type shortcuts.
      #   - `hash` — for attributes whose entries carry multiple sub-properties
      #     (e.g. redirects, with path / canonical / sequence). Use this
      #     instead of nesting a Valkyrie::Resource. See
      #     `documentation/redirects.md` for a worked example.
      #   - Any primitive Valkyrie type, looked up under `Valkyrie::Types::*`
      #     by classified name (e.g. `string` → `Valkyrie::Types::String`).
      #
      # Raises `ArgumentError` if nothing matches.
      #
      # @param [String]
      # @return [Dry::Types::Type]
      def type_for(type) # rubocop:disable Metrics/MethodLength
        case type
        when 'id'
          Valkyrie::Types::ID
        when 'uri'
          Valkyrie::Types::URI
        when 'date_time'
          Valkyrie::Types::DateTime
        when 'hash'
          Dry::Types['hash']
        when 'linked_record'
          Valkyrie::Types::String
        else
          "Valkyrie::Types::#{type.classify}".safe_constantize ||
            raise(ArgumentError, "Unrecognized type: #{type}")
        end
      end
    end

    class UndefinedSchemaError < ArgumentError; end

    private

    def definitions(_schema_name, _version, _contexts)
      raise NotImplementedError, 'Implement #definitions in a child class'
    end

    def config_search_paths
      Hyrax.config.schema_loader_config_search_paths
    end
  end
end

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
      definitions(schema, version, contexts).each_with_object({}) do |definition, hash|
        hash[definition.name] = definition.type.meta(definition.config)
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
        (config.fetch('indexing', nil) || config.fetch('index_keys', []))&.reject { |k| ['facetable', 'stored_searchable', 'admin_only'].include?(k) }&.map(&:to_sym) || []
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
      # No-op wrapper for single-value attributes. Lets `#type` build its
      # output the same way regardless of whether the attribute holds one
      # value or many: `wrapper.of(member_type)` either wraps it (Array)
      # or hands it back unchanged (Identity).
      #
      # @example
      #   Identity.of(Valkyrie::Types::String) # => Valkyrie::Types::String
      class Identity
        ##
        # @param [Dry::Types::Type]
        # @return [Dry::Types::Type] the type passed in
        def self.of(type)
          type
        end
      end

      private

      ##
      # Resolves a `type:` value from a schema YAML to a Dry::Types::Type.
      #
      # Recognized values:
      #   - `id`, `uri`, `date_time` — Valkyrie type shortcuts.
      #   - `hash` — for attributes whose entries carry multiple sub-fields
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
      def type_for(type)
        case type
        when 'id'
          Valkyrie::Types::ID
        when 'uri'
          Valkyrie::Types::URI
        when 'date_time'
          Valkyrie::Types::DateTime
        when 'hash'
          Dry::Types['hash']
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

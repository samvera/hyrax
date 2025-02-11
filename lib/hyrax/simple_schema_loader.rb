# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # This is a simple yaml config-driven schema loader
  #
  # @see config/metadata/basic_metadata.yaml for an example configuration
  class SimpleSchemaLoader
    ##
    # @param [Symbol] schema
    #
    # @return [Hash<Symbol, Dry::Types::Type>] a map from attribute names to
    #   types
    def attributes_for(schema:)
      definitions(schema).each_with_object({}) do |definition, hash|
        hash[definition.name] = definition.type.meta(definition.config)
      end
    end

    ##
    # @param [Symbol] schema
    #
    # @return [Hash{Symbol => Hash{Symbol => Object}}]
    def form_definitions_for(schema:)
      definitions(schema).each_with_object({}) do |definition, hash|
        next if definition.form_options.empty?

        hash[definition.name] = definition.form_options
      end
    end

    ##
    # @param [Symbol] schema
    #
    # @return [{Symbol => Symbol}] a map from index keys to attribute names
    def index_rules_for(schema:)
      definitions(schema).each_with_object({}) do |definition, hash|
        definition.index_keys.each do |key|
          hash[key] = definition.name
        end
      end
    end

    def permissive_schema_for_valkrie_adapter
      metadata_files.each_with_object({}) do |schema_name, ret_hsh|
        predicate_pairs(ret_hsh, schema_name)
      end
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
        @name   = name.to_sym
      end

      ##
      # @return [Hash{Symbol => Object}]
      def form_options
        config.fetch('form', {}).symbolize_keys
      end

      ##
      # @return [Enumerable<Symbol>]
      def index_keys
        config.fetch('index_keys', []).map(&:to_sym)
      end

      ##
      # @return [Dry::Types::Type]
      def type
        collection_type = if config['multiple']
                            Valkyrie::Types::Array.constructor { |v| Array(v).select(&:present?) }
                          else
                            Identity
                          end
        collection_type.of(type_for(config['type']))
      end

      ##
      # @api private
      #
      # This class acts as a Valkyrie/Dry::Types collection with typed members,
      # but instead of wrapping the given type with itself as the collection type
      # (as in `Valkyrie::Types::Array.of(MyType)`), it returns the given type.
      #
      # @example
      #   Identity.of(Valkyrie::Types::String) # => Valkyrie::Types::String
      #
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
      # Maps a configuration string value to a `Valkyrie::Type`.
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
        else
          "Valkyrie::Types::#{type.capitalize}".constantize
        end
      end
    end

    class UndefinedSchemaError < ArgumentError; end

    private

    ##
    # @param [#to_s] schema_name
    # @return [Enumerable<AttributeDefinition]
    def definitions(schema_name)
      schema_config(schema_name)['attributes'].map do |name, config|
        AttributeDefinition.new(name, config)
      end
    end

    ##
    # @param [#to_s] schema_name
    # @return [Hash]
    def schema_config(schema_name)
      schema_config_path = config_paths(schema_name).find { |path| File.exist? path }
      raise(UndefinedSchemaError, "No schema defined: #{schema_name}") unless schema_config_path

      YAML.safe_load(File.open(schema_config_path))
    end

    def config_paths(schema_name)
      config_search_paths.collect { |root_path| root_path.to_s + "/config/metadata/#{schema_name}.yaml" }
    end

    def config_search_paths
      Hyrax.config.simple_schema_loader_config_search_paths
    end

    def metadata_files
      file_name_arr = []
      config_search_paths.each { |root_path| file_name_arr += Dir.entries(root_path.to_s + "/config/metadata/") }
      file_name_arr.reject { |fn| !fn.include?('.yaml') }.uniq.map { |y| y.gsub('.yaml', '') }
    end

    def predicate_pairs(ret_hsh, schema_name)
      schema_config(schema_name)['attributes'].each do |name, config|
        predicate = RDF::URI(config['predicate'])
        if ret_hsh[name].blank?
          ret_hsh[name.to_sym] = predicate
        elsif ret_hsh[name] != predicate
          multiple_predicate_message(name, ret_hsh[name], predicate)
        end
      end
    end

    def multiple_predicate_message(name, existing, incoming)
      message =  "The attribute of #{name} has been assigned a predicate multiple times " \
                 "within the metadata YAMLs. Please be aware that once the attribute's " \
                 "predicate value is first assigned, any other value will be ignored. " \
                 "The existing value is #{existing} preventing the use of #{incoming}"
      Hyrax.logger.warn(message)
    end
  end
end

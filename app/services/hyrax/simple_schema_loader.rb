# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # This is a simple yaml config-driven schema loader
  #
  # @see config/metadata/basic_metadata.yaml for an example configuration
  class SimpleSchemaLoader < Hyrax::SchemaLoader
    def view_definitions_for(schema:, _version: 1)
      schema.each_with_object({}) do |property, metadata|
        view_options = property.meta['view']
        metadata[property.name.to_s] = view_options unless view_options.nil?
      end
    end

    def permissive_schema_for_valkrie_adapter
      metadata_files.each_with_object({}) do |schema_name, ret_hsh|
        predicate_pairs(ret_hsh, schema_name)
      end
    end

    private

    ##
    # @param [#to_s] schema_name
    # @return [Enumerable<AttributeDefinition]
    def definitions(schema_name, _version)
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
      [Rails.root, Hyrax::Engine.root]
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
      message = "The attribute of #{name} has been assigned a predicate multiple times " \
        "within the metadata YAMLs. Please be aware that once the attribute's " \
        "predicate value is first assigned, any other value will be ignored. " \
        "The existing value is #{existing} preventing the use of #{incoming}"
      Hyrax.logger.warn(message)
    end
  end
end

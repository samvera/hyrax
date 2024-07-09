# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # Read m3 profiles from the database
  #
  # @see config/metadata_profiles/m3_profile.yaml for an example configuration
  class M3SchemaLoader < Hyrax::SchemaLoader
    def view_definitions_for(schema:, version: 1)
      definitions(schema, version).each_with_object({}) do |definition, hash|
        next if definition.view_options.empty?

        hash[definition.name] = definition.view_options
      end
    end

    private

    ##
    # @param [#to_s] schema_name
    # @return [Enumerable<AttributeDefinition]
    def definitions(schema_name, version)
      schema = Hyrax::FlexibleSchema.find_by(id: version) || Hyrax::FlexibleSchema.default_schema
      schema.attributes_for(schema_name).map do |name, config|
        AttributeDefinition.new(name, config)
      end
    rescue NoMethodError
      raise UndefinedSchemaError, "Flexible schema not found in version #{version} for #{schema_name}"
    end
  end
end

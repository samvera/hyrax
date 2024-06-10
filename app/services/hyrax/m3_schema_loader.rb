# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # Read m3 profiles from the database
  #
  # @see config/metadata/m3_profile.yaml for an example configuration
  class M3SchemaLoader < Hyrax::SchemaLoader
    private

    ##
    # @param [#to_s] schema_name
    # @return [Enumerable<AttributeDefinition]
    def definitions(schema_name, version)
      Hyrax::FlexibleSchema.find(version).attributes_for(schema_name).map do |name, config|
        AttributeDefinition.new(name, config)
      end
    rescue NoMethodError
      raise UndefinedSchemaError, "Flexible schema not found in version #{version} for #{schema_name}"
    end
  end
end

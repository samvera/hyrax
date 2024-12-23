# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # Read m3 profiles from the database
  #
  # @see config/metadata_profiles/m3_profile.yaml for an example configuration
  class M3SchemaLoader < Hyrax::SchemaLoader
    def view_definitions_for(schema:, version: 1, contexts: nil)
      definitions(schema, version, contexts).each_with_object({}) do |definition, hash|
        next if definition.view_options.empty?

        hash[definition.name] = definition.view_options
      end
    end

    private

    ##
    # @param [#to_s] schema_name
    # @return [Enumerable<AttributeDefinition]
    def definitions(schema_name, version, contexts = nil)
      schema = Hyrax::FlexibleSchema.find_by(id: version) || Hyrax::FlexibleSchema.create_default_schema
      schema.attributes_for(schema_name).map do |name, config|
        # We might be able to consolidate these conditions, but they have been kept separate to make it easier to reason about
        # If there is a context filter on the metadata field and no context is set, skip it
        next if contexts.blank? && config['context'].present?

        # If there is a context filter on the metadata field and we have set a context, but the context does not match, skip it
        next if contexts.present? && config['context'].present? && !contexts.intersect?(config['context'])

        # Wew, we are in the clear to use this field
        AttributeDefinition.new(name, config)
      end.compact
    rescue ActiveRecord::StatementInvalid
      Rails.logger.error "Skipping definition load for migrations to run"
      []
    rescue NoMethodError
      raise UndefinedSchemaError, "Flexible schema not found in version #{version} for #{schema_name}"
    end
  end
end

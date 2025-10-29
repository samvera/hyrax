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
        view_options = definition.view_options
        next if view_options.without(:display_label).empty?

        hash[definition.name] = definition.view_options
      end
    end

    private

    ##
    # @param [#to_s] schema_name
    # @return [Enumerable<AttributeDefinition]
    def definitions(schema_name, version, contexts = nil)
      schema = Hyrax::FlexibleSchema.find_by(id: version) || Hyrax::FlexibleSchema.create_default_schema
      attributes = schema.attributes_for(schema_name)
      attributes ||= fallback_schema_for(schema_name)
      attributes.map do |name, config|
        # We might be able to consolidate these conditions, but they have been kept separate to make it easier to reason about
        # If there is a context filter on the metadata field and no context is set, skip it
        next if contexts.blank? && config['context'].present?

        # If there is a context filter on the metadata field and we have set a context, but the context does not match, skip it
        next if contexts.present? && config['context'].present? && !(Array(contexts) & Array(config['context'])).any?

        # Wew, we are in the clear to use this field
        AttributeDefinition.new(name, config)
      end.compact
    rescue ActiveRecord::StatementInvalid
      Rails.logger.error "Skipping definition load for migrations to run"
      []
    end

    # rubocop:disable Metrics/MethodLength
    def fallback_schema_for(_schema_name)
      { "title" =>
        { "cardinality" => { "minimum" => 1 },
          "data_type" => "array",
          "controlled_values" => { "format" => "http://www.w3.org/2001/XMLSchema#string", "sources" => ["null"] },
          "definition" =>
          { "default" =>
            "Enter a standardized title for display. If only one title is needed, transcribe the title from the source itself." },
          "display_label" => { "default" => "Title" },
          "index_documentation" => "displayable, searchable",
          "indexing" => ["title_sim", "title_tesim"],
          "form" => { "primary" => true, "multiple" => true },
          "mappings" =>
          { "metatags" => "twitter:title, og:title",
            "mods_oai_pmh" => "mods:titleInfo/mods:title",
            "qualified_dc_pmh" => "dcterms:title",
            "simple_dc_pmh" => "dc:title" },
          "property_uri" => "http://purl.org/dc/terms/title",
          "range" => "http://www.w3.org/2001/XMLSchema#string",
          "requirement" => "required",
          "sample_values" => ["Pencil drawn portrait study of woman"],
          "view" => { "label" => { "en" => "Title", "es" => "Título" }, "html_dl" => true },
          "type" => "string",
          "predicate" => "http://purl.org/dc/terms/title",
          "index_keys" => ["title_sim", "title_tesim"],
          "multiple" => true,
          "context" => nil } }
    end
    # rubocop:enable Metrics/MethodLength
  end
end

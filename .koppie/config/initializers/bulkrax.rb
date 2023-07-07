# frozen_string_literal: true

Bulkrax.setup do |config|
  # Add local parsers
  # config.parsers += [
  #   { name: 'MODS - My Local MODS parser', class_name: 'Bulkrax::ModsXmlParser', partial: 'mods_fields' },
  # ]

  # WorkType to use as the default if none is specified in the import
  # Default is the first returned by Hyrax.config.curation_concerns, stringified
  # config.default_work_type = "MyWork"

  # Factory Class to use when generating and saving objects
  config.object_factory = Bulkrax::ValkyrieObjectFactory

  # Path to store pending imports
  # config.import_path = 'tmp/imports'

  # Path to store exports before download
  # config.export_path = 'tmp/exports'

  # Server name for oai request header
  # config.server_name = 'my_server@name.com'

  # NOTE: Creating Collections using the collection_field_mapping will no longer be supported as of Bulkrax version 3.0.
  #       Please configure Bulkrax to use related_parents_field_mapping and related_children_field_mapping instead.
  # Field_mapping for establishing a collection relationship (FROM work TO collection)
  # This value IS NOT used for OAI, so setting the OAI parser here will have no effect
  # The mapping is supplied per Entry, provide the full class name as a string, eg. 'Bulkrax::CsvEntry'
  # The default value for CSV is collection
  # Add/replace parsers, for example:
  # config.collection_field_mapping['Bulkrax::RdfEntry'] = 'http://opaquenamespace.org/ns/set'

  # Field mappings
  # Create a completely new set of mappings by replacing the whole set as follows
  #   config.field_mappings = {
  #     "Bulkrax::OaiDcParser" => { **individual field mappings go here*** }
  #   }

  # Add to, or change existing mappings as follows
  #   e.g. to exclude date
  #   config.field_mappings["Bulkrax::OaiDcParser"]["date"] = { from: ["date"], excluded: true  }
  #
  #   e.g. to import parent-child relationships
  #   config.field_mappings['Bulkrax::CsvParser']['parents'] = { from: ['parents'], related_parents_field_mapping: true }
  #   config.field_mappings['Bulkrax::CsvParser']['children'] = { from: ['children'], related_children_field_mapping: true }
  #   (For more info on importing relationships, see Bulkrax Wiki: https://github.com/samvera-labs/bulkrax/wiki/Configuring-Bulkrax#parent-child-relationship-field-mappings)
  #
  # #   e.g. to add the required source_identifier field
  #   #   config.field_mappings["Bulkrax::CsvParser"]["source_id"] = { from: ["old_source_id"], source_identifier: true  }
  # If you want Bulkrax to fill in source_identifiers for you, see below

  # To duplicate a set of mappings from one parser to another
  #   config.field_mappings["Bulkrax::OaiOmekaParser"] = {}
  #   config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

  # Should Bulkrax make up source identifiers for you? This allow round tripping
  # and download errored entries to still work, but does mean if you upload the
  # same source record in two different files you WILL get duplicates.
  # It is given two aruguments, self at the time of call and the index of the reocrd
  #    config.fill_in_blank_source_identifiers = ->(parser, index) { "b-#{parser.importer.id}-#{index}"}
  # or use a uuid
  #    config.fill_in_blank_source_identifiers = ->(parser, index) { SecureRandom.uuid }

  # Properties that should not be used in imports/exports. They are reserved for use by Hyrax.
  # config.reserved_properties += ['my_field']

  # List of Questioning Authority properties that are controlled via YAML files in
  # the config/authorities/ directory. For example, the :rights_statement property
  # is controlled by the active terms in config/authorities/rights_statements.yml
  # Defaults: 'rights_statement' and 'license'
  # config.qa_controlled_properties += ['my_field']

  # Specify the delimiter regular expression for splitting an attribute's values into a multi-value array.
  # config.multi_value_element_split_on = /\s*[:;|]\s*/.freeze

  # Specify the delimiter for joining an attribute's multi-value array into a string.  Note: the
  # specific delimeter should likely be present in the multi_value_element_split_on expression.
  # config.multi_value_element_join_on = ' | '
end

# Sidebar for hyrax 3+ support
if Object.const_defined?(:Hyrax) && ::Hyrax::DashboardController&.respond_to?(:sidebar_partials)
  Hyrax::DashboardController.sidebar_partials[:repository_content] << "hyrax/dashboard/sidebar/bulkrax_sidebar_additions"
end

class BulkraxTransactionContainer
  extend Dry::Container::Mixin

  namespace "work_resource" do |ops|
    ops.register "create_with_bulk_behavior" do
      steps = Hyrax::Transactions::WorkCreate::DEFAULT_STEPS.dup
      steps[steps.index("work_resource.add_file_sets")] = "work_resource.add_bulkrax_files"

      Hyrax::Transactions::WorkCreate.new(steps: steps)
    end

    ops.register "update_with_bulk_behavior" do
      steps = Hyrax::Transactions::WorkUpdate::DEFAULT_STEPS.dup
      steps[steps.index("work_resource.add_file_sets")] = "work_resource.add_bulkrax_files"

      Hyrax::Transactions::WorkUpdate.new(steps: steps)
    end

    # TODO: uninitialized constant BulkraxTransactionContainer::InlineUploadHandler
    # ops.register "add_file_sets" do
    #   Hyrax::Transactions::Steps::AddFileSets.new(handler: InlineUploadHandler)
    # end

    ops.register "add_bulkrax_files" do
      Bulkrax::Transactions::Steps::AddFiles.new
    end
  end
end

Hyrax::Transactions::Container.merge(BulkraxTransactionContainer)

module HasMappingExt
  ##
  # Field of the model that can be supported
  def field_supported?(field)
    field = field.gsub("_attributes", "")

    return false if excluded?(field)
    return true if supported_bulkrax_fields.include?(field)
    # title is not defined in M3
    return true if field == "title"

    property_defined = factory_class.singleton_methods.include?(:properties) && factory_class.properties[field].present?

    factory_class.method_defined?(field) && (Bulkrax::ValkyrieObjectFactory.schema_properties(factory_class).include?(field) || property_defined)
  end

  ##
  # Determine a multiple properties field
  def multiple?(field)
    @multiple_bulkrax_fields ||=
      %W[
        file
        remote_files
        rights_statement
        #{related_parents_parsed_mapping}
        #{related_children_parsed_mapping}
      ]

    return true if @multiple_bulkrax_fields.include?(field)
    return false if field == "model"
    # title is not defined in M3
    return false if field == "title"

    field_supported?(field) && (multiple_field?(field) || factory_class.singleton_methods.include?(:properties) && factory_class&.properties&.[](field)&.[]("multiple"))
  end

  def multiple_field?(field)
    form_definition = schema_form_definitions[field.to_sym]
    form_definition.nil? ? false : form_definition.multiple?
  end

  # override: we want to directly infer from a property being multiple that we should split when it's a String
  # def multiple_metadata(content)
  #   return unless content

  #   case content
  #   when Nokogiri::XML::NodeSet
  #     content&.content
  #   when Array
  #     content
  #   when Hash
  #     Array.wrap(content)
  #   when String
  #     String(content).strip.split(Bulkrax.multi_value_element_split_on)
  #   else
  #     Array.wrap(content)
  #   end
  # end

  def schema_form_definitions
    @schema_form_definitions ||= ::SchemaLoader.new.form_definitions_for(factory_class.name.underscore.to_sym)
  end
end

[Bulkrax::HasMatchers, Bulkrax::HasMatchers.singleton_class].each do |mod|
  mod.prepend HasMappingExt
end

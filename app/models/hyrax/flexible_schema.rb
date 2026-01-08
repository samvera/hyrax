# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength
class Hyrax::FlexibleSchema < ApplicationRecord
  serialize :profile, coder: YAML
  serialize :contexts, coder: YAML

  validate :validate_profile

  before_save :update_contexts

  def self.current_version
    order("created_at asc").last&.profile
  end

  def self.current_schema_id
    order("created_at asc").last&.id
  end

  def self.create_default_schema
    m3_profile_path = Hyrax::Schema.m3_schema_loader.config_paths&.first
    raise ArgumentError, "No M3 profile found, check the Hyrax.config.schema_loader_config_search_paths" unless m3_profile_path
    schema = Hyrax::FlexibleSchema.first
    return if schema
    Hyrax::FlexibleSchema.create(profile: YAML.safe_load_file(m3_profile_path), validate: false)
  end

  # Retrieve the properties for the model / work type
  # This is a class method called by the model at class load
  #   meaning AdminSet is not available and we cannot get the
  #   contextual dynamic_schema
  # Instead we use the default (contextless) dynamic_schema
  #   which will add all properties available for that class
  # @return [Array] property#to_sym
  def self.default_properties
    current_version['properties'].symbolize_keys!.keys
  rescue StandardError
    []
  end

  # Retrieve the required data to use for mappings
  def self.mappings_data_for(mapping = 'simple_dc_pmh')
    # for OAI-PMH we need the mappings and indexing info
    # for properties with the specified mapping
    return {} unless current_version
    current_version['properties'].each_with_object({}) do |(key, values), obj|
      next unless values['mappings'] && values['mappings'][mapping]
      obj[key] = {
        'indexing' => values['indexing'],
        'mappings' => { mapping => values['mappings'][mapping] }
      }
    end
  end

  def update_contexts
    self.contexts = profile['contexts']
  end

  def title
    "#{profile['profile']['responsibility_statement']} - version #{id}"
  end

  def attributes_for(class_name)
    class_names[class_name]
  end

  def schema_version
    profile['m3_version']
  end

  def context_select
    contexts&.map { |k, v| [v&.[]('display_label'), k] }
  end

  def metadata_profile_type
    profile['profile']['type']
  end

  def version
    id
  end

  def profile_created_at
    created_at.strftime("%b %d, %Y")
  end

  private

  def validate_profile
    validation_service = Hyrax::FlexibleSchemaValidatorService.new(profile:)
    validation_service.validate!

    validation_service.errors.each do |e|
      errors.add(:profile, e.to_s)
    end
  end

  def class_names
    return @class_names if @class_names
    @class_names = {}
    profile['classes'].keys.each do |class_name|
      @class_names[class_name] = {}
    end
    profile['properties'].each do |key, values|
      values['available_on']['class'].each do |property_class|
        # map some m3 items to what Hyrax expects
        values = values_map(values)
        @class_names[property_class][key] = values unless @class_names[property_class].nil?
      end
    end
    @class_names
  end

  def values_map(values)
    values['type'] = lookup_type(values['range'])
    values['predicate'] = values['property_uri']
    values['index_keys'] = values['indexing']
    values['context'] = values.dig('available_on', 'context')
    values['multiple'] = determine_multiplicity(values)

    normalize_form_attributes(values)

    values
  end

  def determine_multiplicity(values)
    return values['data_type'] == 'array' if values.key?('data_type')
    return values['multi_value'] if values.key?('multi_value')

    if (card = values['cardinality'])
      max = card['maximum']
      return max.nil? || max.to_i > 1
    end

    false
  end

  def normalize_form_attributes(values)
    return unless values['form']

    # Rename `multi_value` key to `multiple` (legacy support)
    values['form']['multiple'] = values['form'].delete('multi_value') if values['form'].key?('multi_value')

    values['form']['multiple'] = values['form'].delete('data_type') == 'array' if values['form'].key?('data_type')

    assign_required_flag(values)
  end

  def assign_required_flag(values)
    return unless (card = values['cardinality']) && card['minimum']

    return if values['form'].key?('required')

    required_flag = card['minimum'].to_i.positive?
    values['form']['required'] = required_flag
  end

  def lookup_type(range)
    case range
    when "http://www.w3.org/2001/XMLSchema#dateTime"
      'date_time'
    else
      range.split('#').last.underscore
    end
  end
end
# rubocop:enable Metrics/ClassLength

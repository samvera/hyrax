# frozen_string_literal: true
class Hyrax::FlexibleSchema < ApplicationRecord
  serialize :profile, coder: YAML
  serialize :contexts, coder: YAML

  validate :validate_profile_classes

  before_save :update_contexts

  def self.current_version
    order("created_at asc").last.profile
  end

  def self.current_schema_id
    order("created_at asc").last.id
  end

  def self.create_default_schema
    Hyrax::FlexibleSchema.first_or_create do |f|
      f.profile = YAML.safe_load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml'))
    end
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

  # Retrieve the latest schema definitions for a specific class name.
  def self.definitions_for(class_name:)
    profile = current_version
    definitions = {}
    return definitions unless profile && profile['properties']

    profile['properties'].each do |key, values|
      next unless values['available_on']&.[]('class')&.include?(class_name)

      processed_values = values.deep_dup
      range = processed_values['range']
      processed_values['type'] = case range
                                 when "http://www.w3.org/2001/XMLSchema#dateTime"
                                   'date_time'
                                 else
                                   range&.split('#')&.last&.underscore || 'string'
                                 end
      processed_values['form']&.transform_keys!('multi_value' => 'multiple')
      processed_values['predicate'] = processed_values['property_uri']
      processed_values['index_keys'] = processed_values['indexing']
      processed_values['multiple'] = processed_values['multi_value']
      processed_values['context'] = processed_values['available_on']&.[]('context')

      definitions[key] = processed_values
    end
    definitions
  rescue StandardError => e
    Rails.logger.error("Error fetching definitions for #{class_name}: #{e.message}")
    {}
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

  def validate_profile_classes
    required_classes = [
      Hyrax.config.collection_model,
      Hyrax.config.file_set_model,
      Hyrax.config.admin_set_model
    ]

    if profile['classes'].blank?
      errors.add(:profile, "Must specify classes")
    else
      missing_classes = required_classes - profile['classes'].keys
      unless missing_classes.empty?
        missing_classes_list = missing_classes.join(', ')
        errors.add(:profile, "Must include #{missing_classes_list}")
      end
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
        @class_names[property_class][key] = values
      end
    end
    @class_names
  end

  def values_map(values)
    values['type'] = lookup_type(values['range'])
    values['form']&.transform_keys!('multi_value' => 'multiple')
    values['predicate'] = values['property_uri']
    values['index_keys'] = values['indexing']
    values['multiple'] = values['multi_value']
    values['context'] = values['available_on']['context']
    values
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

# frozen_string_literal: true
class Hyrax::FlexibleSchema < ApplicationRecord
  serialize :profile, coder: YAML
  
  validate :validate_profile_classes

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
    self.current_version['properties'].symbolize_keys!.keys
  rescue StandardError => e
    []
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

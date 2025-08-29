# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength
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
    m3_profile_path = Hyrax.config.default_m3_profile_path || Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml')
    Hyrax::FlexibleSchema.first_or_create do |f|
      f.profile = YAML.safe_load_file(m3_profile_path)
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

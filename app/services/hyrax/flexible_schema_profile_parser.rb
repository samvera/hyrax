# frozen_string_literal: true

module Hyrax
  # This class is responsible for parsing the schema profile for FlexibleSchema.
  class FlexibleSchemaProfileParser
    def self.class_names_for(profile)
      new(profile).class_names
    end

    def initialize(profile)
      @profile = profile
    end

    def class_names
      return @class_names if @class_names

      @class_names = @profile['classes'].keys.index_with { |_k| {} }

      @profile['properties'].each do |prop_name, prop_values|
        prop_values.dig('available_on', 'class')&.each do |class_name|
          next unless @class_names.key?(class_name)
          @class_names[class_name][prop_name] = values_map(prop_values.dup)
        end
      end

      @class_names
    end

    private

    def values_map(values)
      values['type'] = lookup_type(values['range'])
      normalize_form_for(values)
      values['predicate']  = values['property_uri']
      values['index_keys'] = values['indexing']
      values['multiple'] = determine_multiple(values)
      values['context'] = values.dig('available_on', 'context')
      values
    end

    def normalize_form_for(values)
      form = values['form'] || {}
      # Rename `multi_value` key to `multiple` (legacy support)
      form['multiple'] = form.delete('multi_value') if form.key?('multi_value')
      form['multiple'] = form.delete('data_type') == 'array' if form.key?('data_type')
      # Set required flag from cardinality if not already provided
      if (card = values['cardinality']) && card['minimum']
        form['required'] = card['minimum'].to_i.positive?
      end
      values['form'] = form if form.present?
    end

    def determine_multiple(values)
      # Determine if the field should accept multiple values.
      return values['data_type'] == 'array' if values.key?('data_type')
      return values['multi_value'] if values.key?('multi_value')
      if (card = values['cardinality'])
        # When `cardinality` is present, treat maximum > 1 or undefined as multiple
        max = card['maximum']
        return max.nil? || max.to_i > 1
      end
      false
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
end

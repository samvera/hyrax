class Hyrax::FlexibleSchema < ApplicationRecord
  serialize :profile, coder: YAML

  def title
    "#{profile['profile']['responsibility_statement']} - version #{id}"
  end

  def attributes_for(class_name)
    class_names[class_name]
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

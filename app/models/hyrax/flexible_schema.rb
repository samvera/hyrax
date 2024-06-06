class Hyrax::FlexibleSchema < ApplicationRecord
  serialize :profile, coder: YAML

  def attributes_for(class_name)
    class_names[class_name]
  end

  def class_names
    return @class_names if @class_names
    @class_names = {}
    profile['classes'].keys.each do |class_name|
      @class_names[class_name] = {}
    end
    profile['properties'].each do |key, value|
      value['available_on']['class'].each do |property_class|
        # map some m3 items to what Hyrax expects
        value['type'] = lookup_type(value['range'])
        value['predicate'] = value['property_uri']
        @class_names[property_class][key] = value
      end
    end
    @class_names
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

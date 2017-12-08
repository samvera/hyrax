json.extract! @resource, *[:id] + @resource.class.fields.reject { |f| [:internal_resource].include? f }
json.version @resource.etag

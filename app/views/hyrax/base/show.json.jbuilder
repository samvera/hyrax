json.extract! @curation_concern, *[:id] + @curation_concern.class.fields.reject { |f| [:internal_resource].include? f }
json.version @curation_concern.etag

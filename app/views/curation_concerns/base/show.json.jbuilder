json.extract! @curation_concern, *[:id] + @curation_concern.class.fields.select {|f| ![:has_model].include? f}
json.version @curation_concern.etag

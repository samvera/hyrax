# frozen_string_literal: true
json.extract! @curation_concern, *[:id] + @curation_concern.class.fields.reject { |f| [:has_model].include? f }
json.version @curation_concern.try(:etag)

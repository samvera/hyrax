# frozen_string_literal: true
@curation_concern = ::Wings::ActiveFedoraConverter.convert(resource: @curation_concern) if
  @curation_concern.is_a?(Hyrax::Resource) && Object.const_defined?("Wings")

json.extract! @curation_concern, *@curation_concern.class.fields.reject { |f| [:has_model].include? f }
json.id @curation_concern.id.to_s
json.version @curation_concern.try(:etag)

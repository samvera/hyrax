json.extract! @curation_concern, *[:id] + @curation_concern.class.fields.reject { |f| [:has_model].include? f }
json.version @curation_concern.etag

if @curation_concern.is_a? Valkyrie::Resource
  json.id @curation_concern.id.id
  json.access_control_id @curation_concern.access_control_id.id
  json.representative_id @curation_concern.representative_id.id
  json.thumbnail_id @curation_concern.thumbnail_id.id
  json.alternate_ids @curation_concern.alternate_ids.map(&:id)
  json.member_of_collection_ids @curation_concern.member_of_collection_ids.map(&:id)
  json.member_ids @curation_concern.member_ids.map(&:id)
  json.access_control_ids @curation_concern.access_control_ids.map(&:id)
  json.list_source_ids @curation_concern.list_source_ids.map(&:id)
  json.related_object_ids @curation_concern.related_object_ids.map(&:id)
  json.representative_ids @curation_concern.representative_ids.map(&:id)
  json.thumbnail_ids @curation_concern.thumbnail_ids.map(&:id)
end

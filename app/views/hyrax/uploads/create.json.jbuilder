# frozen_string_literal: true
json.files [@upload] do |uploaded_file|
  json.id uploaded_file.id
  json.name uploaded_file.filename
  json.size uploaded_file.byte_size
  # TODO: implement these
  # json.url  "/uploads/#{uploaded_file.id}"
  # json.thumbnail_url uploaded_file.id
  json.deleteUrl hyrax.uploaded_file_path(uploaded_file)
  json.deleteType 'DELETE'
end

json.files [@uploaded_file] do |uploaded_file|
  json.id uploaded_file.id
  json.name uploaded_file.file.file.filename
  json.size uploaded_file.file.file.size
  json.url  "/uploads/#{uploaded_file.id}"
  json.thumbnail_url uploaded_file.id
  json.delete_url "deleteme"
  json.delete_type "DELETE"
end

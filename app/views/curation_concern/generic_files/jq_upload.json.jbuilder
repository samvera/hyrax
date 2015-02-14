json.array! [@generic_file] do |generic_file|
  json.name generic_file.title.first
  json.size generic_file.file_size.first
  json.url  "/files/#{generic_file.id}"
  json.thumbnail_url generic_file.id
  json.delete_url "deleteme"
  json.delete_type "DELETE"
end

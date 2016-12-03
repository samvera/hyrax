json.array! [@file_set] do |file_set|
  json.name file_set.title.first
  json.size file_set.file_size.first
  json.url  "/files/#{file_set.id}"
  json.thumbnail_url file_set.id
  json.delete_url "deleteme"
  json.delete_type "DELETE"
end

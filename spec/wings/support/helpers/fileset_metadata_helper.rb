def add_metadata_to_file(file)
  # These are accessible from the FileSet through...
  #   fileset1.files.first.metadata_node.attributes
  file.file_name = 'picture.jpg'
  file.content = 'hello world'
  file.date_created = Date.parse 'Fri, 08 May 2015 08:00:00 -0400 (EDT)'
  file.date_modified = Date.parse 'Sat, 09 May 2015 09:00:00 -0400 (EDT)'
  file.byte_order = 'little-endian'
  file.mime_type = 'application/jpg'
  file
end


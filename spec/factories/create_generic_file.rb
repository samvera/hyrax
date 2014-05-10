def FactoryGirl.create_generic_file(container_factory_name_or_object, user, file = nil, &block)
  curation_concern =
  if container_factory_name_or_object.is_a?(Symbol)
    FactoryGirl.create_curation_concern(container_factory_name_or_object, user)
  else
    container_factory_name_or_object
  end

  generic_file = Worthwhile::GenericFile.new

  yield(generic_file) if block_given?

  generic_file.visibility ||= Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED


  Sufia::GenericFile::Actions.create_metadata(generic_file, user, curation_concern.pid) do |gf|
    gf.batch = curation_concern
    gf.visibility = (generic_file.visibility)
  end

  if file
    file ||= Rack::Test::UploadedFile.new(__FILE__, 'text/plain', false)
    generic_file.file ||= file
    Sufia::GenericFile::Actions.create_content(
      generic_file,
      file,
      file.original_filename,
      'content',
      user
    )
  end
  return generic_file
end

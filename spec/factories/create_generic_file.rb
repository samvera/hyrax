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


  actor = Sufia::GenericFile::Actor.new(generic_file, user)
  actor.create_metadata(curation_concern.pid) do |gf|
    gf.batch = curation_concern # I'm fairly certain we can remove this line
    gf.visibility = (generic_file.visibility)
  end

  if file
    file ||= Rack::Test::UploadedFile.new(__FILE__, 'text/plain', false)
    generic_file.file ||= file
    actor.create_content( file, file.original_filename, 'content')
  end
  return generic_file
end

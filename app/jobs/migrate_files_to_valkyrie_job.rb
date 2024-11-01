##
# Responsible for conditionally enqueuing the file and thumbnail migration
# logic of an ActiveFedora object.
class MigrateFilesToValkyrieJob < Hyrax::ApplicationJob
  ##
  #
  # @param resource [Hyrax::FileSet]
  def perform(resource)
    migrate_derivatives!(resource:)
    # need to reload file_set to get the derivative ids
    resource = Hyrax.query_service.find_by(id: resource.id)
    migrate_files!(resource: resource)
  end

  def attribute_mapping
    return @attribute_mapping if @attribute_mapping
    @attribute_mapping = %w[
      aspect_ratio bit_depth bit_rate byte_order capture_device channels character_count character_set
      checksum color_map color_space compression creator data_format duration exif_version file_title
      fits_version format_label frame_rate gps_timestamp graphics_count height image_producer language
      latitude line_count longitude markup_basis markup_language offset orientation page_count
      paragraph_count profile_name profile_version recorded_size sample_rate scanning_software
      table_count well_formed width word_count ].inject({}) { |j, i| j[i] = i; j}
    @attribute_mapping['recorded_size'] = 'file_size'
    @attribute_mapping['channels'] = 'alpha_channels'
    @attribute_mapping['checksum'] = 'original_checksum'
    @attribute_mapping
  end

  private

  def migrate_derivatives!(resource:)
    # @todo should we trigger a job if the member is a child work?
    paths = Hyrax::DerivativePath.derivatives_for_reference(resource)
    paths.each do |path|
      container = container_for(path)
      mime_type = Marcel::MimeType.for(extension: File.extname(path))
      directives = { url: path, container: container, mime_type: mime_type }
      File.open(path, 'rb') do |content|
        Hyrax::ValkyriePersistDerivatives.call(content, directives)
      end
    end
  end

  ##
  # Move the ActiveFedora files out of ActiveFedora's domain and into the
  # configured {Hyrax.storage_adapter}'s domain.
  def migrate_files!(resource:)
    return unless resource.respond_to?(:file_ids)

    files = Hyrax.custom_queries.find_many_file_metadata_by_ids(ids: resource.file_ids)
    files.each do |file|
      # If it doesn't start with fedora, we've likely already migrated it.
      next unless /^fedora:/.match?(file.file_identifier.to_s)
      resource.file_ids.delete(file.id)

      Tempfile.create do |tempfile|
        tempfile.binmode
        tempfile.write(URI.open(file.file_identifier.to_s.gsub("fedora:", "http:")).read)
        tempfile.rewind

        # valkyrie_file = Hyrax.storage_adapter.upload(resource: resource, file: tempfile, original_filename: file.original_filename)
        valkyrie_file = Hyrax::ValkyrieUpload.file(
          filename: resource.label,
          file_set: resource,
          io: tempfile,
          use: file.pcdm_use.select {|use| Hyrax::FileMetadata::Use.use_list.include?(use)},
          user: User.find_or_initialize_by(User.user_key_field => resource.depositor),
          mime_type: file.mime_type,
          skip_derivatives: true
        )
        valkyrie_file = copy_attributes(valkyrie_file:, original_file: file)
        Hyrax.persister.save(resource: valkyrie_file)
      end
    end
    # reindex the file set after migrating files to include characterization info
    Hyrax.index_adapter.save(resource: resource)
  end

  def copy_attributes(valkyrie_file:, original_file:)
    attribute_mapping.each do |k, v|
      valkyrie_file.set_value(k, original_file.send(v))
    end
    # Special case as this property isn't in the characterization proxy
    valkyrie_file.set_value('alternate_ids', original_file.alternate_ids)
    valkyrie_file
  end

  ##
  # Map from the file name used for the derivative to a valid option for
  # container that ValkyriePersistDerivatives can convert into a
  # Hyrax::Metadata::Use
  #
  # @param filename [String] the name of the derivative file: i.e. 'x-thumbnail.jpg'
  # @return [String]
  def container_for(filename)
    # we want the portion between the '-' and the '.'
    file_blob = File.basename(filename, '.*').split('-').last

    case file_blob
    when 'thumbnail'
      'thumbnail_image'
    when 'txt', 'json', 'xml'
      'extracted_text'
    else
      'service_file'
    end
  end
end

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
      end
    end
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

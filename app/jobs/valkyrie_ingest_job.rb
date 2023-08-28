# frozen_string_literal: true

##
# Ingests a {Hyrax::UploadedFile} as file member of a {Hyrax::FileSet}.
#
# The {Hyrax::UploadedFile} is passed into {#perform}, and should have a
# {Hyrax::UploadedFile#file_set_uri} identifying an existing {Hyrax::FileSet}.
class ValkyrieIngestJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  ##
  # @param [Hyrax::UploadedFile] file
  # @param [RDF::URI] pcdm_use is the use/type to apply to the created FileMetadata
  # @see Hyrax::FileMetadata::Use
  def perform(file, pcdm_use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
    ingest(file: file, pcdm_use: pcdm_use)
  end

  ##
  # @api private
  #
  # @param [Hyrax::UploadedFile] file
  # @param [RDF::URI] pcdm_use
  # @return [void]
  def ingest(file:, pcdm_use:)
    file_set_uri = Valkyrie::ID.new(file.file_set_uri)
    file_set = Hyrax.query_service.find_by(id: file_set_uri)
    upload_file(
      file: file,
      file_set: file_set,
      pcdm_use: pcdm_use,
      user: file.user
    )
  end

  ##
  # @api private
  #
  # @param [Hyrax::UploadedFile] file
  # @param [Hyrax::FileSet] file_set
  # @param [RDF::URI] pcdm_use  the use/type to apply to the created FileMetadata
  # @param [User] user
  #
  # @return [Hyrax::FileMetadata] the metadata representing the uploaded file
  def upload_file(file:, file_set:, pcdm_use:, user: nil)
    carrier_wave_sanitized_file = file.uploader.file
    # Pull file, since carrierwave files don't respond to a proper IO #read. See
    # https://github.com/carrierwaveuploader/carrierwave/issues/1959
    file_io = carrier_wave_sanitized_file.to_file

    ::Hyrax::ValkyrieUpload.file(
      io: file_io,
      filename: carrier_wave_sanitized_file.original_filename,
      file_set: file_set,
      use: pcdm_use,
      user: user
    )
  end
end

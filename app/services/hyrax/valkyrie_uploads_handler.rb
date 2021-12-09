# frozen_string_literal: true

##
# Accepts uploaded files via `#add` and attaches them to a Work with `#attach`,
# avoiding the AF assumptions of the default implementation.
#
# @todo replace `Lockable` Redis locks with database transactions?
class Hyrax::ValkyrieUploadsHandler < Hyrax::WorkUploadsHandler
  ##
  # @api public
  #
  # Create filesets for each added file, then push the uploads to the storage
  # backend.
  #
  # @return [Boolean]
  def attach
    return true if Array.wrap(files).empty?

    event_payloads = []

    acquire_lock_for(work.id) do
      event_payloads = files.map { |file| attach_member(file: file) }.to_a

      @persister.save(resource: work) &&
        Hyrax.publisher.publish("object.metadata.updated", object: work, user: files.first.user)
    end

    event_payloads.each { |payload| Hyrax.publisher.publish("file.set.attached", payload) }

    ingest(files: files)
  end

  private

  ##
  # @api private
  #
  # @return [Hash{Symbol => Object}] event payloads for `file.set.attached`
  #   events. we want to publish these after updating the work metadata
  def attach_member(file:)
    file_set = @persister.save(resource: Hyrax::FileSet.new(file_set_args(file)))
    file.add_file_set!(file_set) # update carrierwave db record

    Hyrax::AccessControlList.copy_permissions(source: target_permissions, target: file_set)

    append_to_work(file_set)
    Hyrax.publisher.publish("object.metadata.updated", object: file_set, user: file.user)

    { file_set: file_set, user: file.user }
  end

  ##
  # @api private
  #
  # @return [void]
  def ingest(files:)
    files.map do |file|
      file_set = Hyrax.query_service.find_by(id: file.file_set_uri)
      file_metadata = upload_file(file: file, file_metadata: file_metadata, file_set: file_set)
      add_file_to_file_set(file_set: file_set, file_metadata: file_metadata)
    end
  end

  ##
  # @api private
  #
  # @return FileSet updated file set
  def add_file_to_file_set(file_set:, file_metadata:)
    file_set.file_ids << file_metadata.id
    Hyrax.persister.save(resource: file_set)
  end

  ##
  # @api private
  #
  # @return Hyrax::FileMetadata uploaded file
  def upload_file(file:, file_metadata:, file_set:)
    uploader = file.uploader
    file_metadata = Hyrax::FileMetadata.for(file: uploader.file)
    file_metadata.file_set_id = file.file_set_uri
    uploaded = Hyrax.storage_adapter
                    .upload(resource: file_set,
                            file: File.open(uploader.file.file),
                            original_filename: file_metadata.original_filename)
    file_metadata.file_identifier = uploaded.id
    file_metadata.size = uploaded.size

    # characterization is run on the Hyrax::FileMetadata, but re-indexing is
    # only triggered when the FileSet is persisted, so we need to pass that
    # through as well
    Hyrax.publisher.publish(
      "object.file.uploaded",
      file_set: file_set,
      metadata: file_metadata
    )

    file_metadata
  end
end

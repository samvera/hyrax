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
  # @return [void]
  def ingest(files:)
    files.map do |file|
      uploader = file.uploader
      file_metadata = Hyrax::FileMetadata.for(file: uploader.file)
      file_metadata.file_set_id = file.file_set_uri
      file_metadata = Hyrax.persister.save(resource: file_metadata)

      file_set = Hyrax.query_service.find_by(id: file.file_set_uri)
      file_set.file_ids << file_metadata.id
      Hyrax.persister.save(resource: file_set)

      uploaded = Hyrax.storage_adapter
        .upload(resource: file_metadata,
          file: File.open(uploader.file.file),
          original_filename: file_metadata.original_filename)
      file_metadata.file_identifier = uploaded.id
      file_metadata.size = uploaded.size
      Hyrax.persister.save(resource: file_metadata)

      Hyrax.publisher.publish("object.file.uploaded", metadata: file_metadata)
    end
  end

  ##
  # @api private
  # @return [Hash{Symbol => Object}] event payloads for `file.set.attached`
  #   events. we want to publish these after updating the work metadata
  def attach_member(file:)
    file_set = @persister.save(resource: Hyrax::FileSet.new(file_set_args(file)))
    file.add_file_set!(file_set) # update carrierwave db record

    Hyrax::AccessControlList.copy_permissions(source: target_permissions, target: file_set)

    append_to_work(file_set)
    Hyrax.publisher.publish("object.metadata.updated", object: file_set, user: file.user)

    {file_set: file_set, user: file.user}
  end
end

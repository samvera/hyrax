# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < ActiveJob::Base
  queue_as Hyrax.config.ingest_queue_name

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<UploadedFile>] uploaded_files - an array of files to attach
  def perform(work, uploaded_files)
    user = User.find_by_user_key(work.depositor)
    work_permissions = work.permissions.map(&:to_hash)
    uploaded_files.each do |uploaded_file|
      file_set = FileSet.new
      actor = Hyrax::Actors::FileSetActor.new(file_set, user)
      actor.create_metadata(visibility: work.visibility)
      attach_content(actor, uploaded_file.file)
      actor.attach_file_to_work(work)
      actor.file_set.permissions_attributes = work_permissions
      uploaded_file.update(file_set_uri: file_set.uri)
    end
  end

  private

    # @param [Hyrax::Actors::FileSetActor] actor
    # @param [UploadedFileUploader] file
    def attach_content(actor, file)
      case file.file
      when CarrierWave::SanitizedFile
        actor.create_content(file.file.to_file)
      when CarrierWave::Storage::Fog::File
        import_url(actor, file)
      else
        raise ArgumentError, "Unknown type of file #{file.class}"
      end
    end

    # @param [Hyrax::Actors::FileSetActor] actor
    # @param [UploadedFileUploader] file
    def import_url(actor, file)
      actor.file_set.update(import_url: file.url)
      operation = Hyrax::Operation.create!(user: actor.user,
                                           operation_type: "Attach File")
      ImportUrlJob.perform_later(actor.file_set, operation)
    end
end

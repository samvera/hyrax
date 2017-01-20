# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < ActiveJob::Base
  queue_as Hyrax.config.ingest_queue_name

  # @param [ActiveFedora::Base] the work class
  # @param [Array<UploadedFile>] an array of files to attach
  def perform(work, uploaded_files)
    uploaded_files.each do |uploaded_file|
      file_set = FileSet.new
      user = User.find_by_user_key(work.depositor)
      actor = Hyrax::Actors::FileSetActor.new(file_set, user)
      actor.create_metadata(visibility: work.visibility)
      attach_content(actor, uploaded_file.file)
      actor.attach_file_to_work(work)
      actor.file_set.permissions_attributes = work.permissions.map(&:to_hash)

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
      log = Hyrax::Operation.create!(user: actor.user,
                                     operation_type: "Attach File")
      ImportUrlJob.perform_later(actor.file_set, log)
    end
end

# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < ActiveJob::Base
  queue_as Hyrax.config.ingest_queue_name

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<UploadedFile>] uploaded_files - an array of files to attach
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
    # @param [Hyrax::UploadedFileUploader] file file.file must be a CarrierWave::SanitizedFile or file.url must be present
    def attach_content(actor, file)
      if file.file.is_a? CarrierWave::SanitizedFile
        actor.create_content(file.file.to_file)
      elsif file.url.present?
        actor.import_url(file.url)
      else
        raise ArgumentError, "#{file.class} received with #{file.file.class} object and no URL"
      end
    end
end

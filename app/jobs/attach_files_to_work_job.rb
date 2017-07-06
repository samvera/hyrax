# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform(work, uploaded_files, **work_attributes)
    user = User.find_by_user_key(work.depositor)
    work_permissions = work.permissions.map(&:to_hash)
    uploaded_files.each do |uploaded_file|
      file_set = FileSet.new
      actor = Hyrax::Actors::FileSetActor.new(file_set, user)
      actor.create_metadata(visibility_attributes(work_attributes))
      attach_content(actor, uploaded_file)
      actor.attach_to_work(work)
      actor.file_set.permissions_attributes = work_permissions
      uploaded_file.update(file_set_uri: file_set.uri)
    end
  end

  private

    # @param [Hyrax::Actors::FileSetActor] actor
    # @param [Hyrax::UploadedFile] uploaded_file .uploader.file must be a CarrierWave::SanitizedFile or .uploader.url must be present
    def attach_content(actor, uploaded_file)
      file_uploader = uploaded_file.uploader
      if file_uploader.file.is_a? CarrierWave::SanitizedFile
        actor.create_content(file_uploader.file.to_file)
      elsif file_uploader.url.present?
        actor.import_url(file_uploader.url)
      else
        raise ArgumentError, "#{file_uploader.class} received with #{file_uploader.file.class} object and no URL"
      end
    end

    # The attributes used for visibility - used to send as initial params to
    # created FileSets.
    def visibility_attributes(attributes)
      attributes.slice(:visibility, :visibility_during_lease,
                       :visibility_after_lease, :lease_expiration_date,
                       :embargo_release_date, :visibility_during_embargo,
                       :visibility_after_embargo)
    end
end

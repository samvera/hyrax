# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < ActiveJob::Base
  queue_as :attach_files

  # @param [ActiveFedora::Base] the work class
  # @param [Array<UploadedFile>] an array of files to attach
  def perform(work, uploaded_files)
    uploaded_files.each do |uploaded_file|
      file_set = FileSet.new
      user = User.find_by_user_key(work.depositor)
      actor = CurationConcerns::FileSetActor.new(file_set, user)
      actor.create_metadata(work, visibility: work.visibility)
      actor.create_content(uploaded_file.file.current_path)
      # Set the uri so that we know this uploaded file has been used.
      uploaded_file.update(file_set_uri: file_set.uri)
    end
  end
end

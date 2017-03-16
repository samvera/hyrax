module Hyrax
  # Store a file uploaded by a user. Eventually these files get
  # attached to FileSets and pushed into Fedora.
  class UploadedFile < ActiveRecord::Base
    self.table_name = 'uploaded_files'
    mount_uploader :file, UploadedFileUploader
    belongs_to :user, class_name: '::User'

    before_destroy :remove_file!
  end
end

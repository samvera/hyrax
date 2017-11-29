module Hyrax
  # Store a file uploaded by a user. Eventually these files get
  # attached to FileSets and pushed into Fedora.
  class UploadedFile < ActiveRecord::Base
    self.table_name = 'uploaded_files'
    mount_uploader :file, UploadedFileUploader
    alias uploader file
    has_many :job_io_wrappers,
             inverse_of: 'uploaded_file',
             class_name: 'JobIoWrapper',
             dependent: :destroy
    belongs_to :user, class_name: '::User'

    before_destroy :remove_file!
  end
end

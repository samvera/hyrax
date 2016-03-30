# Store a file uploaded by a user. Eventually these files get
# attached to FileSets and pushed into Fedora.
class UploadedFile < ActiveRecord::Base
  mount_uploader :file, UploadedFileUploader
  belongs_to :user
end

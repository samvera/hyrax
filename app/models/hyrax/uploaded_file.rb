# frozen_string_literal: true
module Hyrax
  ##
  # Store a file uploaded by a user.
  #
  # Eventually these files get attached to {FileSet}s and pushed into Fedora.
  class UploadedFile < ActiveRecord::Base
    self.table_name = 'uploaded_files'
    mount_uploader :file, UploadedFileUploader
    alias uploader file
    has_many :job_io_wrappers,
             inverse_of: 'uploaded_file',
             class_name: 'JobIoWrapper',
             dependent: :destroy
    belongs_to :user, class_name: '::User'

    ##
    # Associate a {FileSet} with this uploaded file.
    #
    # @param [Hyrax::Resource, ActiveFedora::Base] file_set
    # @return [void]
    def add_file_set!(file_set)
      uri = case file_set
            when ActiveFedora::Base
              file_set.uri
            when Hyrax::Resource
              file_set.id
            end
      update!(file_set_uri: uri)
    end
  end
end

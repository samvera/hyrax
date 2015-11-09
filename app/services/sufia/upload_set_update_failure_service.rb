module Sufia
  class UploadSetUpdateFailureService < MessageUserService
    attr_reader :upload_set_id

    def initialize(file_set, user, upload_set_id)
      @upload_set_id = upload_set_id
      super(file_set, user)
    end

    def message
      "The upload set upload for #{upload_set_id} failed"
    end

    def subject
      'Failing Upload Set Update'
    end
  end
end

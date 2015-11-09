module Sufia
  class UploadSetUpdateSuccessService < MessageUserService
    attr_reader :upload_set_id

    def initialize(file_set, user, upload_set_id)
      @upload_set_id = upload_set_id
      super(file_set, user)
    end

    def message
      "The upload set update for  #{upload_set_id} passed."
    end

    def subject
      'Passing Upload Set Update'
    end
  end
end

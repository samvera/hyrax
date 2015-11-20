module Sufia
  class UploadSetUpdateFailureService < MessageUserService
    attr_reader :upload_set

    def initialize(user, upload_set)
      @upload_set = upload_set
      @user = user
    end

    def message
      "The upload set upload for #{upload_set.id} failed"
    end

    def subject
      'Failing Upload Set Update'
    end
  end
end

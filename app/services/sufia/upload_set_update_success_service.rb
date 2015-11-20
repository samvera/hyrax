module Sufia
  class UploadSetUpdateSuccessService < MessageUserService
    attr_reader :upload_set

    def initialize(user, upload_set)
      @upload_set = upload_set
      @user = user
    end

    def message
      "The upload set update for #{upload_set.id} passed."
    end

    def subject
      'Passing Upload Set Update'
    end
  end
end

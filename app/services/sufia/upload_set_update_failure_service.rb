module Sufia
  class UploadSetUpdateFailureService < MessageUserService
    attr_reader :user
    def initialize(user)
      @user = user
    end

    def message
      "The upload set upload for #{user} failed"
    end

    def subject
      'Failing Upload Set Update'
    end
  end
end

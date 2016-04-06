module Sufia
  class UploadSetUpdateSuccessService < MessageUserService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def message
      "The upload set update for #{user} passed."
    end

    def subject
      'Passing Upload Set Update'
    end
  end
end

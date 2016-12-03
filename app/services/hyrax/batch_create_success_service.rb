module Hyrax
  class BatchCreateSuccessService < MessageUserService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def message
      "The batch create for #{user} passed."
    end

    def subject
      'Passing batch create'
    end
  end
end

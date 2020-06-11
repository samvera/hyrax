# frozen_string_literal: true
module Hyrax
  class AbstractMessageService
    attr_reader :file_set, :user

    def initialize(file_set, user)
      @file_set = file_set
      @user = user
    end

    def call
      Hyrax::MessengerService.deliver(job_user,
                                      user,
                                      message,
                                      subject)
    end

    # Passed to Hyrax::MessengerService, override to provide message body for event.
    def message
      raise "Override #message in the service class"
    end

    # Passed to Hyrax::MessengerService, override to provide subject for event.
    def subject
      raise "Override #subject in the service class"
    end

    private

    def job_user
      ::User.audit_user
    end
  end
end

module Sufia
  class MessageUserService
    attr_reader :file_set, :user

    def initialize(file_set, user)
      @file_set = file_set
      @user = user
    end

    def call
      job_user.send_message(user, message, subject)
    end

    # Passed into send_message, override to provide message body for event.
    def message
      raise "Override #message in the service class"
    end

    # Passed into send_message, override to provide subject for event.
    def subject
      raise "Override #subject in the service class"
    end

    private

      def job_user
        ::User.audit_user
      end
  end
end

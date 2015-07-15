module Sufia
  class MessageUserService
    attr_reader :generic_file, :user

    def initialize(generic_file, user)
      @generic_file = generic_file
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
        ::User.audituser
      end
  end
end

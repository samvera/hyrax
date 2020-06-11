# frozen_string_literal: true
module Hyrax
  class MessengerService
    def self.deliver(sender, recipients, body, subject, *args)
      sender.send_message(recipients, body, subject, *args)
      StreamNotificationsJob.perform_later(recipients)
    end
  end
end

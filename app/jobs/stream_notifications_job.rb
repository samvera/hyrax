# frozen_string_literal: true
class StreamNotificationsJob < Hyrax::ApplicationJob
  def perform(users)
    # Do not use the ActionCable machinery if the feature is disabled
    return unless Hyrax.config.realtime_notifications?
    Array.wrap(users).each do |user|
      mailbox = UserMailbox.new(user)
      Hyrax::NotificationsChannel.broadcast_to(user,
                                               notifications_count: mailbox.unread_count,
                                               notifications_label: mailbox.label)
    end
  end
end

# frozen_string_literal: true
module Hyrax
  class NotificationsChannel < ApplicationCable::Channel
    def subscribed
      stream_for current_user
    end

    def unsubscribed
      stop_all_streams
    end

    def update_locale(data)
      current_user.update(preferred_locale: data['locale'])
    end
  end
end

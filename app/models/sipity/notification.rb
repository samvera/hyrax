# frozen_string_literal: true
module Sipity
  # Responsible for defining a notification that is associated with a given
  # context; I believe the context is something that will be triggered via
  # an action however, I don't believe this needs to be a "hard"
  # relationship. It is instead a polymorphic relationship.
  class Notification < ActiveRecord::Base
    self.table_name = 'sipity_notifications'

    has_many :notifiable_contexts,
             dependent: :destroy,
             class_name: 'Sipity::NotifiableContext'

    has_many :recipients,
             dependent: :destroy,
             class_name: 'Sipity::NotificationRecipient'

    NOTIFICATION_TYPE_EMAIL = 'email'

    # TODO: There are other types, but for now, we are assuming just emails to send.
    enum :notification_type, { NOTIFICATION_TYPE_EMAIL => NOTIFICATION_TYPE_EMAIL }

    def self.valid_notification_types
      notification_types.keys
    end
  end
end

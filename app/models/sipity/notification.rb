module Sipity
  # Responsible for defining a notification that is associated with a given
  # context; I believe the context is something that will be triggered via
  # an action however, I don't believe this needs to be a "hard"
  # relationship. It is instead a polymorphic relationship.
  class Notification < ActiveRecord::Base
    self.table_name = 'sipity_notifications'

    has_many :notifiable_contexts,
             dependent: :destroy,
             foreign_key: :notification_id,
             class_name: 'Sipity::NotifiableContext'

    has_many :recipients,
             dependent: :destroy,
             foreign_key: :notification_id,
             class_name: 'Sipity::NotificationRecipient'
  end
end

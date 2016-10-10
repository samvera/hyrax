module CurationConcerns
  module Workflow
    # Responsible for determining the appropriate notification(s) to deliver based on the given
    # criteria.
    class NotificationService
      # For the given :entity and :action
      # - For each associated notification
      # - - Generate the type of notification
      # - - Expand the notification roles to users
      # - - Deliver the notification to the users
      def self.deliver_on_action_taken(entity:, action:, comment:, user:)
        new(entity: entity,
            action: action,
            comment: comment,
            user: user).call
      end

      def initialize(entity:, action:, comment:, user:)
        @entity = entity
        @action = action
        @comment = comment
        @user = user
      end

      attr_reader :action, :entity, :comment, :user

      def call
        action.notifiable_contexts.each do |ctx|
          send_notification(ctx.notification)
        end
      end

      def send_notification(notification)
        notifier = notifier(notification)
        return unless notifier
        notifier.send_notification(notification: notification,
                                   entity: entity,
                                   comment: comment,
                                   user: user)
      end

      def notifier(notification)
        class_name = notification.name.classify
        klass = begin
                  class_name.constantize
                rescue NameError
                  Rails.logger.error "Unable to find '#{class_name}', so not sending notification"
                  return nil
                end
        return klass if klass.respond_to?(:send_notification)
        Rails.logger.error "Expected '#{class_name}' to respond to 'send_notification', but it didn't, so not sending notification"
        nil
      end

      def resolve_recipients(notification)
      end
    end
  end
end

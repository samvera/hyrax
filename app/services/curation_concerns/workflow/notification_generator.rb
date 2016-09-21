module CurationConcerns
  module Workflow
    class NotificationGenerator
      # @api public
      def self.call(**kwargs)
        new(**kwargs).call
      end

      # @param workflow [Sipity::Workflow] The containing workflow for this notification; Without the workflow the scope is meaningless
      # @param reason [#to_s] Why is this notification being sent? Did we enter a state? Was an action taken?
      # @param scope [Object] The specific name (or object) of associated with the reason (i.e. "submit_for_review" would be the scope)
      # @param notification_name [#to_s] The unique name of the notification to send
      # @param recipients [Hash] With keys of :to, :cc, :bcc
      # @param notification_type
      def initialize(workflow:, reason:, scope:, notification_name:, recipients:, notification_type:)
        self.workflow = workflow
        self.reason = reason
        self.notification_name = notification_name
        self.notification_type = notification_type
        self.recipients = recipients
        assign_scope(scope: scope, reason: reason)
      end

      def call
        notification = persist_notification
        assign_recipients_to(notification: notification)
        assign_scope_and_reason_to(notification: notification)
      end

      private

      def persist_notification
        Sipity::Notification.find_or_create_by!(name: notification_name, notification_type: notification_type)
      end

      def assign_recipients_to(notification:)
        recipients.slice(:to, :cc, :bcc).each do |(recipient_strategy, recipient_roles)|
          Array.wrap(recipient_roles).each do |role|
            notification.recipients.find_or_create_by!(
              role: PowerConverter.convert_to_sipity_role(role), recipient_strategy: recipient_strategy.to_s
            )
          end
        end
      end

      def assign_scope_and_reason_to(notification:)
        Sipity::NotifiableContext.find_or_create_by!(
          scope_for_notification: scope,
          reason_for_notification: reason,
          notification: notification
        )
      end

      attr_accessor :workflow, :reason, :notification_name, :recipients, :notification_type
      attr_reader :scope

      # Note this is a rather hideous switch statement related to coercing data.
      def assign_scope(scope:, reason:)
        @scope = begin
          case reason
          when Sipity::NotifiableContext::REASON_ACTION_IS_TAKEN
            PowerConverter.convert_to_sipity_action(scope, scope: workflow)
          when Sipity::NotifiableContext::REASON_ENTERED_STATE
            PowerConverter.convert_to_sipity_workflow_state(scope, scope: workflow)
          end
        end
      end
    end
  end
end

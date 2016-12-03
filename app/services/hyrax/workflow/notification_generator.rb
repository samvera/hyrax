module Hyrax
  module Workflow
    # Responsible for writing the database records for the given :workflow and :notification_configuration.
    class NotificationGenerator
      # @api public
      #
      # @param workflow [Sipity::Workflow]
      # @param notification_configuration [Hyrax::Workflow::NotificationConfigurationParameter]
      # @return [Sipity::Notification]
      def self.call(workflow:, notification_configuration:)
        new(workflow: workflow, notification_configuration: notification_configuration).call
      end

      # @param workflow [Sipity::Workflow] The containing workflow for this notification; Without the workflow the scope is meaningless
      # @param notification_configuration [Hyrax::Workflow::NotificationConfigurationParameter]
      def initialize(workflow:, notification_configuration:)
        self.workflow = workflow
        self.notification_configuration = notification_configuration
        assign_scope!
      end

      def call
        notification = persist_notification
        assign_recipients_to(notification: notification)
        assign_scope_and_reason_to(notification: notification)
        notification
      end

      private

        def persist_notification
          Sipity::Notification.find_or_create_by!(
            name: notification_configuration.notification_name,
            notification_type: notification_configuration.notification_type
          )
        end

        def assign_recipients_to(notification:)
          notification_configuration.recipients.slice(:to, :cc, :bcc).each do |(recipient_strategy, recipient_roles)|
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
            reason_for_notification: notification_configuration.reason,
            notification: notification
          )
        end

        attr_accessor :workflow, :notification_configuration
        attr_reader :scope

        def assign_scope!
          @scope = PowerConverter.convert_to_sipity_action(notification_configuration.scope, scope: workflow)
        end
    end
  end
end

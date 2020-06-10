# frozen_string_literal: true
module Hyrax
  module Workflow
    # Helps consolidate and map a notification configuration.
    #
    # @note In an effort to appease Rubocop, I'm crafting this parameter object. It makes more sense anyway.
    class NotificationConfigurationParameter
      def self.build_from_workflow_action_configuration(workflow_action:, config:)
        notification_name = config.fetch(:name)
        notification_type = config.fetch(:notification_type)
        recipients = config.slice(:to, :cc, :bcc)
        new(
          notification_name: notification_name,
          reason: Sipity::NotifiableContext::REASON_ACTION_IS_TAKEN,
          recipients: recipients,
          notification_type: notification_type,
          scope: workflow_action
        )
      end

      include Dry::Equalizer(:reason, :scope, :notification_name, :recipients, :notification_type)

      def initialize(reason:, scope:, notification_name:, recipients:, notification_type:)
        self.reason = reason
        self.scope = scope
        self.notification_name = notification_name
        self.recipients = recipients
        self.notification_type = notification_type
      end

      attr_accessor :notification_name, :recipients, :notification_type

      # Why are we sending the notification?
      #
      # @see Sipity::NotifiableContext::REASON_ACTION_IS_TAKEN
      attr_accessor :reason

      # For the given reason, there is a scope for that reason. Examples
      # of scope include an action name or a state name.
      attr_accessor :scope
    end
  end
end

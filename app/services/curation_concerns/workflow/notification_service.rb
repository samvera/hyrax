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
        _entity = entity
        _action = action
        _comment = comment
        _user = user
      end
    end
  end
end

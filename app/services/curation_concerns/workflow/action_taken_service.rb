module CurationConcerns
  module Workflow
    # Responsible for performing additional functions when the given criteria is met.
    class ActionTakenService
      # For the given :entity and :action
      # - Find the appropriate "function" to call
      # - Then call that function
      def self.handle_action_taken(entity:, action:, comment:, user:)
        _entity = entity
        _action = action
        _comment = comment
        _user = user
      end
    end
  end
end

module CurationConcerns
  module Workflow
    # This is a built in function for workflow, so that a workflow action can be created that
    # grants the creator the ability to alter it.
    class GrantEditToDepositor
      def self.call(target:, **)
        target.edit_users = [target.depositor]
      end
    end
  end
end

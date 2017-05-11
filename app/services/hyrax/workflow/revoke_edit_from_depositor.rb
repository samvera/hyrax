module Hyrax
  module Workflow
    # This is a built in function for workflow, so that a workflow action can be created that
    # removes the creators the ability to alter it.
    module RevokeEditFromDepositor
      def self.call(target:, **)
        target.edit_users -= [target.depositor]
      end
    end
  end
end

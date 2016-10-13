module CurationConcerns
  module Workflow
    # This is a built in function for workflow, so that a workflow action can be created that
    # removes the creators ability to alter it.
    class RemoveDepositorPermissions
      def self.call(entity:, **)
        entity.proxy_for.edit_users = []
      end
    end
  end
end

# frozen_string_literal: true
module Hyrax
  module Workflow
    ##
    # This is a built in function for workflow, so that a workflow action can be created that
    # removes the creators the ability to alter it.
    module RevokeEditFromDepositor
      def self.call(target:, **)
        return true unless target.try(:depositor)

        model = target.try(:model) || target # get the model if target is a ChangeSet
        model.edit_users = model.edit_users.to_a - Array.wrap(target.depositor)
        model.try(:permission_manager)&.acl&.save

        # If there are a lot of members, revoking access from each could take a
        # long time. Do this work in the background.
        RevokeEditFromMembersJob.perform_later(model, target.depositor)
      end
    end
  end
end

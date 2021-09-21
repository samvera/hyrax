# frozen_string_literal: true
module Hyrax
  module Workflow
    # This is a built in function for workflow, so that a workflow action can be created that
    # removes the creators the ability to alter it.
    module RevokeEditFromDepositor
      def self.call(target:, **)
        return true unless target.try(:depositor)
        target.edit_users = target.edit_users.to_a - Array.wrap(target.depositor)

        target.try(:permission_manager)&.acl&.save

        # If there are a lot of members, revoking access from each could take a
        # long time. Do this work in the background.
        RevokeEditFromMembersJob.perform_later(target, target.depositor)
      end
    end
  end
end

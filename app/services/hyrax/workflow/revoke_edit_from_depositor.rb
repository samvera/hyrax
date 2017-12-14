module Hyrax
  module Workflow
    # This is a built in function for workflow, so that a workflow action can be created that
    # removes the creators the ability to alter it.
    module RevokeEditFromDepositor
      # @param [#edit_users=, #depositor] target (likely a work) to which we are removing the depositor from edit_users
      # @return void
      def self.call(target:, **)
        depositor = target.depositor.first
        target.edit_users -= [depositor]
        # If there are a lot of members, revoking access from each could take a
        # long time. Do this work in the background.
        RevokeEditFromMembersJob.perform_later(target, depositor)
      end
    end
  end
end

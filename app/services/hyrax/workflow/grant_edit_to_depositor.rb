module Hyrax
  module Workflow
    # This is a built in function for workflow, so that a workflow action can be created that
    # grants the creator the ability to alter it.
    module GrantEditToDepositor
      # @param [#edit_users=, #depositor] target (likely a work) to which we are adding edit_users for the depositor
      # @return void
      def self.call(target:, **)
        depositor = target.depositor.first
        target.edit_users += [depositor]
        # If there are a lot of members, granting access to each could take a
        # long time. Do this work in the background.
        GrantEditToMembersJob.perform_later(target, depositor)
      end
    end
  end
end

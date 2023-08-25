# frozen_string_literal: true
module Hyrax
  module Workflow
    ##
    # This is a built in function for workflow, so that a workflow action can be created that
    # grants the creator the ability to view their work.
    module GrantReadToDepositor
      # @param [#read_users=, #read_users] target to which we are adding read_users
      #   for the depositor
      # @return void
      def self.call(target:, **)
        return true unless target.try(:depositor)

        model = target.try(:model) || target # get the model if target is a ChangeSet
        model.read_users += Array.wrap(target.depositor)
        model.try(:permission_manager)&.acl&.save

        # If there are a lot of members, granting access to each could take a
        # long time. Do this work in the background.
        GrantReadToMembersJob.perform_later(model, target.depositor)
      end
    end
  end
end

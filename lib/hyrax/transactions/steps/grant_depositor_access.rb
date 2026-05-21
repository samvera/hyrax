# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transaction` step that grants the work's depositor `:edit` access
      # on the work's in-memory ACL.
      #
      # This restores behavior previously provided by the ActiveFedora actor
      # stack's `Hyrax::Actors::BaseActor#apply_depositor_metadata`, which
      # unconditionally added the depositor to `edit_users` at create time. With
      # the move to the Valkyrie `WorkCreate` transaction, no equivalent step
      # existed, leaving depositor edit access to be granted only by workflow
      # actions that include `Hyrax::Workflow::GrantEditToDepositor`. Workflows
      # whose deposit action omits it (e.g. `one_step_mediated_deposit`) left
      # depositors unable to edit their own works.
      #
      # @note Expected to run after `change_set.apply` (so the depositor field
      #   is populated on the persisted work) and before `work_resource.save_acl`
      #   (so the ACL change is persisted).
      class GrantDepositorAccess
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::Work] work
        #
        # @return [Dry::Monads::Result]
        def call(work)
          return Success(work) unless work.respond_to?(:permission_manager)
          return Success(work) if work.depositor.blank?

          work.permission_manager.edit_users += [work.depositor]
          Success(work)
        end
      end
    end
  end
end

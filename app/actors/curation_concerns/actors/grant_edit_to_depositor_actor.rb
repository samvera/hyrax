module CurationConcerns
  module Actors
    # Grants edit access to the depositor.  This is implemented as a separate actor,
    # so that it can be removed from the stack in cases where the depositor should not
    # have edit access (e.g. mediated deposit)
    class GrantEditToDepositorActor < AbstractActor
      def create(attributes)
        grant_edit_access
        next_actor.create(attributes)
      end

      private

        def grant_edit_access
          curation_concern.edit_users += [user.user_key]
        end
    end
  end
end

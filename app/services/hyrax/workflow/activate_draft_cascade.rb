# frozen_string_literal: true
module Hyrax
  module Workflow
    ##
    # Workflow method for the draft publication lifecycle's +activate+ action.
    #
    # Publishes the target work: it takes the chosen active visibility and
    # enqueues {Hyrax::ActivateDraftCascadeJob} to apply that same visibility
    # recursively to the entire membership tree (child works and file sets at
    # every depth), activating suppressed members so they leave the draft state.
    #
    # The chosen visibility arrives as the +target_visibility+ keyword, carried
    # through the workflow-action plumbing from the "Publish draft" form. When
    # absent it defaults to public/open.
    #
    # @see Hyrax::Workflow::ActionTakenService for how the method is invoked
    # @see Hyrax::ActivateDraftCascadeJob for the recursive cascade
    module ActivateDraftCascade
      # Default active visibility when the action carries no explicit choice.
      DEFAULT_VISIBILITY = Hyrax::VisibilityIntention::PUBLIC

      ##
      # @param target [Hyrax::ChangeSet, Valkyrie::Resource] the work being published
      # @param target_visibility [String, nil] the chosen active visibility
      #   (e.g. "open", "authenticated", "restricted"); defaults to open when blank
      #
      # @return [Boolean] truthy so {ActionTakenService} saves the target
      def self.call(target:, target_visibility: nil, **)
        return true unless Flipflop.draft_permission?

        model = target.try(:model) || target
        visibility = target_visibility.presence || DEFAULT_VISIBILITY

        # Promote the root now. The ACL change is saved directly, as
        # GrantReadToDepositor does; ActivateObject (also on this action) returns
        # the root to the active state.
        model.visibility = visibility
        model.try(:permission_manager)&.acl&.save

        # Promote the rest of the tree in the background so large trees don't
        # block the request.
        Hyrax::ActivateDraftCascadeJob.perform_later(model.id.to_s, visibility)
        true
      end
    end
  end
end

# frozen_string_literal: true
module Hyrax
  ##
  # Defines the Hyrax "Actor Stack", used in creation of works when using
  # +ActiveFedora+.
  #
  # @note this stack, and the Actor classes it calls, is not used when
  #   +Valkyrie+ models are defined by the application. in that context,
  #   this behavior is replaced by `Hyrax::Transactions::Container`.
  #
  # @see Hyrax::CurationConcern.actor
  # @see Hyrax::WorksControllerBehavior#create
  # @see Hyrax::WorksControllerBehavior#update
  class DefaultMiddlewareStack
    # rubocop:disable Metrics/MethodLength
    def self.build_stack
      ActionDispatch::MiddlewareStack.new.tap do |middleware|
        # Ensure you are mutating the most recent version
        middleware.use Hyrax::Actors::OptimisticLockValidator

        # Attach files from a URI (for BrowseEverything)
        middleware.use Hyrax::Actors::CreateWithRemoteFilesActor

        # Attach files uploaded in the form to the UploadsController
        middleware.use Hyrax::Actors::CreateWithFilesActor

        # Add/remove the resource to/from a collection
        middleware.use Hyrax::Actors::CollectionsMembershipActor

        # Add/remove to parent work
        middleware.use Hyrax::Actors::AddToWorkActor

        # Add/remove children (works or file_sets)
        middleware.use Hyrax::Actors::AttachMembersActor

        # Set the order of the children (works or file_sets)
        middleware.use Hyrax::Actors::ApplyOrderActor

        # Sets the default admin set if they didn't supply one
        middleware.use Hyrax::Actors::DefaultAdminSetActor

        # Decode the private/public/institution on the form into permisisons on
        # the model
        middleware.use Hyrax::Actors::InterpretVisibilityActor
        #
        # Handles transfering ownership of works from one user to another
        middleware.use Hyrax::Actors::TransferRequestActor

        # Copies default permissions from the PermissionTemplate to the work
        middleware.use Hyrax::Actors::ApplyPermissionTemplateActor

        # Remove attached FileSets when destroying a work
        middleware.use Hyrax::Actors::CleanupFileSetsActor

        # Destroys the trophies in the database when the work is destroyed
        middleware.use Hyrax::Actors::CleanupTrophiesActor

        # Destroys the feature tag in the database when the work is destroyed
        middleware.use Hyrax::Actors::FeaturedWorkActor

        # Persist the metadata changes on the resource
        middleware.use Hyrax::Actors::ModelActor
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end

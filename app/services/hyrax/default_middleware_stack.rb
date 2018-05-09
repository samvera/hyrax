module Hyrax
  class DefaultMiddlewareStack
    # rubocop:disable Metrics/MethodLength
    def self.build_stack
      ActionDispatch::MiddlewareStack.new.tap do |middleware|
        # Wrap everything in a database transaction, if the save of the resource
        # fails then roll back any database AdminSetChangeSet
        middleware.use Hyrax::Actors::TransactionalRequest

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

        # Start the workflow for this work
        middleware.use Hyrax::Actors::InitializeWorkflowActor
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end

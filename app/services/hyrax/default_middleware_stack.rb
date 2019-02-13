module Hyrax
  class DefaultMiddlewareStack
    # rubocop:disable Metrics/MethodLength
    def self.build_stack
      ActionDispatch::MiddlewareStack.new.tap do |middleware|
        # Used to wrap everything in a database transaction, if the save of the resource
        # failed then rolled back any database AdminSetChangeSet
        # This was problematic, is removed in v3.0, and is currently a no-op
        # Backport of https://github.com/samvera/hyrax/pull/3482
        middleware.use Hyrax::Actors::TransactionalRequest
        # Ensure you are mutating the most recent version
        middleware.use Hyrax::Actors::OptimisticLockValidator
        middleware.use Hyrax::Actors::CreateWithRemoteFilesActor
        middleware.use Hyrax::Actors::CreateWithFilesActor
        middleware.use Hyrax::Actors::CollectionsMembershipActor
        middleware.use Hyrax::Actors::AddToWorkActor
        middleware.use Hyrax::Actors::AttachMembersActor
        middleware.use Hyrax::Actors::ApplyOrderActor
        middleware.use Hyrax::Actors::InterpretVisibilityActor
        middleware.use Hyrax::Actors::TransferRequestActor
        middleware.use Hyrax::Actors::DefaultAdminSetActor
        middleware.use Hyrax::Actors::ApplyPermissionTemplateActor
        middleware.use Hyrax::Actors::CleanupFileSetsActor
        middleware.use Hyrax::Actors::CleanupTrophiesActor
        middleware.use Hyrax::Actors::FeaturedWorkActor
        middleware.use Hyrax::Actors::ModelActor
        middleware.use Hyrax::Actors::InitializeWorkflowActor
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end

module Hyrax
  class ActorFactory
    # rubocop:disable Metrics/MethodLength
    def self.stack_actors(curation_concern)
      [Hyrax::Actors::TransactionalRequest,
       Hyrax::Actors::OptimisticLockValidator,
       Hyrax::Actors::CreateWithRemoteFilesActor,
       Hyrax::Actors::CreateWithFilesActor,
       Hyrax::Actors::CollectionsMembershipActor,
       Hyrax::Actors::AddToWorkActor,
       Hyrax::Actors::AssignRepresentativeActor,
       Hyrax::Actors::AttachFilesActor,
       Hyrax::Actors::AttachMembersActor,
       Hyrax::Actors::ApplyOrderActor,
       Hyrax::Actors::InterpretVisibilityActor,
       Hyrax::Actors::DefaultAdminSetActor,
       Hyrax::Actors::ApplyPermissionTemplateActor,
       model_actor(curation_concern),
       # Initialize workflow after model is saved
       Hyrax::Actors::InitializeWorkflowActor]
    end
    # rubocop:enable Metrics/MethodLength

    def self.build(curation_concern, current_ability)
      Actors::ActorStack.new(curation_concern,
                             current_ability,
                             stack_actors(curation_concern))
    end

    def self.model_actor(curation_concern)
      actor_identifier = curation_concern.class.to_s
      "Hyrax::Actors::#{actor_identifier}Actor".constantize
    end
  end
end

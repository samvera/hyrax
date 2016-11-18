module Sufia
  class ActorFactory < CurationConcerns::Actors::ActorFactory
    def self.stack_actors(curation_concern)
      [CreateWithRemoteFilesActor,
       CreateWithFilesActor,
       CurationConcerns::Actors::AddToCollectionActor,
       CurationConcerns::Actors::AddToWorkActor,
       CurationConcerns::Actors::AssignRepresentativeActor,
       CurationConcerns::Actors::AttachFilesActor,
       CurationConcerns::Actors::ApplyOrderActor,
       CurationConcerns::Actors::InterpretVisibilityActor,
       GrantEditToDepositorActor,
       CurationConcerns::Actors::InitializeWorkflowActor,
       ApplyPermissionTemplateActor,
       model_actor(curation_concern)]
    end
  end
end

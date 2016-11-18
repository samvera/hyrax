module Sufia
  class ActorFactory
    def self.stack_actors(curation_concern)
      [CreateWithRemoteFilesActor,
       CreateWithFilesActor,
       Sufia::Actors::AddToCollectionActor,
       Sufia::Actors::AddToWorkActor,
       Sufia::Actors::AssignRepresentativeActor,
       Sufia::Actors::AttachFilesActor,
       Sufia::Actors::ApplyOrderActor,
       Sufia::Actors::InterpretVisibilityActor,
       ApplyPermissionTemplateActor,
       model_actor(curation_concern),
       Sufia::Actors::InitializeWorkflowActor]
    end

    def self.build(curation_concern, current_user)
      Actors::ActorStack.new(curation_concern,
                             current_user,
                             stack_actors(curation_concern))
    end

    def self.model_actor(curation_concern)
      actor_identifier = curation_concern.class.to_s.split('::').last
      "Sufia::Actors::#{actor_identifier}Actor".constantize
    end
  end
end

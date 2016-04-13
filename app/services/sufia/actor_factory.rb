module Sufia
  class ActorFactory < CurationConcerns::ActorFactory
    def self.stack_actors(curation_concern)
      [CreateWithFilesActor,
       CurationConcerns::AddToCollectionActor,
       CurationConcerns::AssignRepresentativeActor,
       CurationConcerns::AttachFilesActor,
       CurationConcerns::ApplyOrderActor,
       CurationConcerns::InterpretVisibilityActor,
       model_actor(curation_concern),
       CurationConcerns::AssignIdentifierActor]
    end
  end
end

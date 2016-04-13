module CurationConcerns
  class ActorFactory
    def self.build(curation_concern, current_user)
      ActorStack.new(curation_concern,
                     current_user,
                     stack_actors(curation_concern))
    end

    def self.stack_actors(curation_concern)
      [AddToCollectionActor,
       AssignRepresentativeActor,
       AttachFilesActor,
       ApplyOrderActor,
       InterpretVisibilityActor,
       model_actor(curation_concern),
       AssignIdentifierActor]
    end

    def self.model_actor(curation_concern)
      actor_identifier = curation_concern.class.to_s.split('::').last
      "CurationConcerns::#{actor_identifier}Actor".constantize
    end
  end
end

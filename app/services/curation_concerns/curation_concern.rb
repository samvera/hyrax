module CurationConcerns
  module CurationConcern
    # Returns the top-level actor on the stack
    def self.actor(curation_concern, current_user, attributes)
      AddToCollectionActor.new(curation_concern, current_user, attributes,
                               [AssignRepresentativeActor,
                                AttachFilesActor,
                                ApplyOrderActor,
                                InterpretVisibilityActor,
                                model_actor(curation_concern),
                                AssignIdentifierActor])
    end

    def self.model_actor(curation_concern)
      actor_identifier = curation_concern.class.to_s.split('::').last
      "CurationConcerns::#{actor_identifier}Actor".constantize
    end
  end
end

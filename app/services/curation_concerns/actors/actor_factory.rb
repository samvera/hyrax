module CurationConcerns
  module Actors
    class ActorFactory
      def self.build(curation_concern, current_user)
        Actors::ActorStack.new(curation_concern,
                               current_user,
                               stack_actors(curation_concern))
      end

      def self.stack_actors(curation_concern)
        [AddToCollectionActor,
         AddToWorkActor,
         AssignRepresentativeActor,
         AttachFilesActor,
         ApplyOrderActor,
         InterpretVisibilityActor,
         GrantEditToDepositorActor,
         model_actor(curation_concern),
         InitializeWorkflowActor]
      end

      def self.model_actor(curation_concern)
        actor_identifier = curation_concern.class.to_s.split('::').last
        "CurationConcerns::Actors::#{actor_identifier}Actor".constantize
      end
    end
  end
end

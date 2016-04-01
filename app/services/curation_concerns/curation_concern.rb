module CurationConcerns
  module CurationConcern
    # Returns the top-level actor on the stack
    def self.actor(curation_concern, current_user)
      ActorStack.new(curation_concern, current_user,
                     [AddToCollectionActor,
                      AssignRepresentativeActor,
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

    class ActorStack
      attr_reader :curation_concern, :user, :first_actor_class, :more_actors
      def initialize(curation_concern, user, more_actors)
        @curation_concern = curation_concern
        @user = user
        @more_actors = more_actors
        @first_actor_class = @more_actors.shift || RootActor
      end

      def inner_stack
        ActorStack.new(curation_concern, user, more_actors)
      end

      def actor
        first_actor_class.new(curation_concern, user, inner_stack)
      end

      def create(attributes)
        actor.create(attributes.with_indifferent_access)
      end

      def update(attributes)
        actor.update(attributes.with_indifferent_access)
      end
    end
  end
end

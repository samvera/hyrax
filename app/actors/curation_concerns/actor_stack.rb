module CurationConcerns
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

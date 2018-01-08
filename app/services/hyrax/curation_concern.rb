module Hyrax
  class CurationConcern
    # The actor middleware stack can be customized like so:
    #   # Adding a new middleware
    #   Hyrax::CurationConcern.actor_factory.use MyCustomActor
    #
    #   # Inserting a new middleware at a specific position
    #   Hyrax::CurationConcern.actor_factory.insert_after Hyrax::Actors::CreateWithRemoteFilesActor, MyCustomActor
    #
    #   # Removing a middleware
    #   Hyrax::CurationConcern.actor_factory.delete Hyrax::Actors::CreateWithRemoteFilesActor
    #
    #   # Replace one middleware with another
    #   Hyrax::CurationConcern.actor_factory.swap Hyrax::Actors::CreateWithRemoteFilesActor, MyCustomActor
    #
    # You can customize the actor stack, so long as you do so before the actor
    # is used.  Once it is used, it becomes immutable.
    # @return [ActionDispatch::MiddlewareStack]
    def self.actor_factory
      @actor_factory ||= Hyrax::DefaultMiddlewareStack.build_stack
    end

    # A consumer of this method can inject a different factory
    # into this class in order to change the behavior of this method.
    # @return [#create, #update] an actor that can create and update the work
    def self.actor
      @work_middleware_stack ||= actor_factory.build(endpoint)
    end

    # @return The class that the actor middleware wraps.
    # This class actually does the create/update/destroy of the object.
    def self.endpoint
      # passing nil because there is no actor following this one.
      Actors::ModelActor.new(nil)
    end
  end
end

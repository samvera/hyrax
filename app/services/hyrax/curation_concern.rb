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
      @work_middleware_stack ||= actor_factory.build(Actors::Terminator.new)
    end

    # NOTE: I don't know why this middleware doesn't use the BaseActor - Justin
    # @return [#create] an actor for creating the FileSet
    def self.file_set_create_actor
      @file_set_create_actor ||= begin
        stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
          middleware.use Actors::InterpretVisibilityActor
        end
        stack.build(Actors::Terminator.new)
      end
    end

    # @return [#update] an actor for updating the FileSet
    def self.file_set_update_actor
      @file_set_update_actor ||= begin
        stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
          middleware.use Actors::InterpretVisibilityActor
          middleware.use Actors::BaseActor
        end
        stack.build(Actors::Terminator.new)
      end
    end
  end
end

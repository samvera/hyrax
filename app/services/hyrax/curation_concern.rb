# frozen_string_literal: true
module Hyrax
  class CurationConcern
    ##
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
    #
    # @return [ActionDispatch::MiddlewareStack]
    # @see Hyrax::DefaultMiddlewareStack
    def self.actor_factory
      @actor_factory ||= Hyrax::DefaultMiddlewareStack.build_stack
    end

    ##
    # Provides the Hyrax "Actor Stack" used during creation of Works when
    # +ActiveFedora+ models are used by the application
    #
    # The "Actor Stack" consists of a series of objects ("Actors"), which
    # implement +#create+, +#update+ and +#destroy+. Each actor's methods
    # promise to call the same methods on the next actor in the series, and may
    # do some work before (on the way down the stack) and/or after (on the
    # way up) calling to the next actor.
    #
    # The normal convention is to call an actor inheriting
    # {Hyrax::Actors::BaseActor} at or near the bottom of the stack, to handle
    # the create, update , or destroy action.
    #
    # @note this stack, and the Actor classes it calls, is not used when
    #   +Valkyrie+ models are defined by the application. in that context,
    #   this behavior is replaced by `Hyrax::Transactions::Container`.
    #
    # @return [#create, #update] an actor that can create and update the work
    #
    # @see Hyrax::DefaultMiddlewareStack
    # @see https://samvera.github.io/actor_stack.html
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

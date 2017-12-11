module Hyrax
  module Actors
    ##
    # `Hyrax::Actors::AbstractActor` implements the base (no-op) case for Hyrax Actor
    # middleware. Concrete implementations may override any or all of the three
    # primary actions:
    #
    # * #create
    # * #update
    # * #destroy
    #
    # Each of these should accept a `Hyrax::Actor::Environment` and return
    # `true` to communicate to middleware further up the stack that execution
    # below this point may be regarded as successful, and `false` to indicate
    # that it has not. In the general case, returning `false` will pop out of
    # the stack--though middleware further up may perform actions or even
    # return `true` in response.
    #
    # The `next_actor` attribute represents the actor immediately down in the
    # stack from the current actor. This variable should be set as an argument
    # to the initializer, but implementations may behave differently, e.g. to
    # insert an actor into the stack at runtime.
    #
    # In order to continue the stack actors must instantiate the next actor in
    # the chain and call the corresponding action method.
    #
    # @example A simple actor that does work on create
    #   class SimpleActor < AbstractActor
    #     def create(env)
    #       # act! is contingent on `next_actor` reporting success
    #       next_actor.create(env) && act!(env.curation_concern)
    #     end
    #
    #     ##
    #     # @param work [Hyrax::Work]
    #     # @return [Boolean] truthy if the work succeeds
    #     def act!(work)
    #       # do some things with work here
    #       true
    #     end
    #   end
    #
    # @example A complex actor that you probably don't want to write.
    #   class ComplexActor < AbstractActor
    #     def create(env)
    #       manipulate_env!(env)
    #       before! # do this regardless of what happens lower in the stack
    #
    #       result = next_actor.create(env) # invoke the next actor
    #
    #       # do after! only if next_actor reported a healthy state, set result
    #       # to reflect this actor's output.
    #       result && (result = after!)
    #
    #       ensure! # do this after next_actor, even in the failure case
    #
    #       result
    #     end
    #     # ...
    #   end
    #
    # @example Using an actor with an ActionDispatch stack
    #   class MyMiddleware < AbstractActor
    #   end
    #
    #   stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
    #     # middleware.use OtherMiddleware
    #     middleware.use MyActor
    #     # middleware.use MoreMiddleware
    #   end
    #
    #   env = Hyrax::Actors::Environment.new(object, ability, attributes)
    #   last_actor = Hyrax::Actors::Terminator.new
    #
    #   stack.build(last_actor).create(env) # or `#update/#destroy`
    #
    # @see ActionDispatch::MiddlewareStack
    # @see Hyrax::DefaultMiddlewareStack
    class AbstractActor
      ##
      # @!attribute next_actor [r]
      #   @return [AbstractActor]
      attr_reader :next_actor

      ##
      # @param next_actor [AbstractActor]
      def initialize(next_actor)
        @next_actor = next_actor
      end

      delegate :create, to: :next_actor

      delegate :update, to: :next_actor

      delegate :destroy, to: :next_actor
    end
  end
end

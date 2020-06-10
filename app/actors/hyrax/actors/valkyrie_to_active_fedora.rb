# frozen_string_literal: true

module Hyrax
  module Actors
    ##
    # Casts `env.curation_concern` from a `Valkyrie::Resource` to an
    # `ActiveFedora::Base` model.
    #
    # If the curation concern is not a `Valkyrie::Resource` this is a
    # no-op.
    #
    # This can be used in conjunction with `ActiveFedoraToValkyrie` to create a
    # vertical boundary in the actor stack between actors that deal with
    # `ActiveFedora` models and those that work on `Valkyrie::Resource` objects.
    #
    # @example defining a stack using both ActiveFedora and Valkyrie actors
    #   stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
    #     middleware.use ActorThatUsesActiveFedora
    #     middleware.use AnotherActorThatUsesActiveFedora
    #     middleware.use ValkyrieToActiveFedora # casts on the way up
    #     middleware.use ActiveFedoraToValkyrie # casts on the way down
    #     middleware.use ActorThatUsesValkyrie
    #     middleware.use AnotherActorThatUsesValkyrie
    #   end
    #
    #   actor = stack.build(Hyrax::Actors::Terminator.new)
    #
    # @see ValkyrieToActiveFedora
    class ValkyrieToActiveFedora < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true
      def create(env)
        next_actor.create(env) && cast(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true
      def update(env)
        next_actor.update(env) && cast(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true
      def destroy(env)
        next_actor.destroy(env) && cast(env)
      end

      private

      def cast(env)
        return true unless env.curation_concern.is_a? Valkyrie::Resource

        env.curation_concern =
          Wings::ActiveFedoraConverter.convert(resource: env.curation_concern)

        true
      end
    end
  end
end

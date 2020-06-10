# frozen_string_literal: true

module Hyrax
  module Actors
    ##
    # Casts `env.curation_concern` from a `ActiveFedora::Base` model to a
    # `Valkyrie::Resource` resource.
    #
    # If the curation concern is not an `ActiveFedora::Base` this is a
    # no-op.
    #
    # This can be used in conjunction with `ValkyrieToActiveFedora` to create a
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
    class ActiveFedoraToValkyrie < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true
      def create(env)
        cast(env) && next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true
      def update(env)
        cast(env) && next_actor.update(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true
      def destroy(env)
        cast(env) && next_actor.destroy(env)
      end

      private

      def cast(env)
        return true unless env.curation_concern.is_a? ActiveFedora::Base

        env.curation_concern = env.curation_concern.valkyrie_resource

        true
      end
    end
  end
end

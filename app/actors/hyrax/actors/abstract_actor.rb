module Hyrax
  module Actors
    # The Hyrax::AbstractActor responds to three primary actions:
    # * #create
    # * #update
    # * #destroy
    #
    # and the next_actor attribute
    #
    #
    # In order to continue the stack it must instantiate the next actor in the chain and call it
    #   OR to exit from the stack, return a truthy or falsey value.
    class AbstractActor
      attr_reader :next_actor

      def initialize(next_actor)
        @next_actor = next_actor
      end

      delegate :create, to: :next_actor

      delegate :update, to: :next_actor

      delegate :destroy, to: :next_actor
    end
  end
end

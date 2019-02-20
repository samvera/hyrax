module Hyrax
  module Actors
    # Used to wrap the stack in a database transaction.
    # This would have rolled back any database actions (particularly workflow) if there
    # is an error elsewhere in the actor stack.
    # This was problematic, is removed in v3.0, and is currently a no-op
    # Backport of https://github.com/samvera/hyrax/pull/3482
    class TransactionalRequest < Actors::AbstractActor
      # rubocop:disable Rails/Delegate
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        next_actor.update(env)
      end
      # rubocop:enable Rails/Delegate
    end
  end
end

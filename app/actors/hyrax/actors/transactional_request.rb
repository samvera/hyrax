module Hyrax
  module Actors
    # Wrap the stack in a database transaction.
    # This will roll back any database actions (particularly workflow) if there
    # is an error elsewhere in the actor stack.
    class TransactionalRequest < Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        ActiveRecord::Base.transaction do
          next_actor.create(env)
        end
      rescue StandardError => err
        # note that this does not catch explicit `ActiveRecord::Rollback` calls.
        env.curation_concern.ensure_valid_minter_state
        raise err
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        ActiveRecord::Base.transaction do
          next_actor.update(env)
        end
      end
    end
  end
end

module Hyrax
  module Actors
    # Wrap the stack in a database transaction.
    # This will roll back any database actions (particularly workflow) if there
    # is an error elsewhere in the actor stack.
    class TransactionalRequest < Actors::AbstractActor
      def create(attributes)
        ActiveRecord::Base.transaction do
          next_actor.create(attributes)
        end
      end

      def update(attributes)
        ActiveRecord::Base.transaction do
          next_actor.update(attributes)
        end
      end
    end
  end
end

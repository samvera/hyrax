
module Hyrax
  module Actors
    # Responsible for removing trophies related to the given curation concern.
    class CleanupTrophiesActor < Hyrax::Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy(env)
        cleanup_trophies(env)
        next_actor.destroy(env)
      end

      private

      def cleanup_trophies(env)
        Trophy.where(work_id: env.curation_concern.id).destroy_all
      end
    end
  end
end

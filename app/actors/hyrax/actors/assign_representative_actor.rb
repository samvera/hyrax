module Hyrax
  module Actors
    class AssignRepresentativeActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        next_actor.create(env) && assign_representative(env)
      end

      private

        def assign_representative(env)
          unless env.curation_concern.representative_id
            # TODO: Possible optimization here. Does this cause a fetch of ordered_members if they're already loaded?
            representative = nil # curation_concern.ordered_members.association.reader.first.target
            env.curation_concern.representative = representative if representative
          end
          env.curation_concern.save
        end
    end
  end
end

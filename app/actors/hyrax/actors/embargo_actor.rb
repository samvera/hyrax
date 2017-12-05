module Hyrax
  module Actors
    class EmbargoActor
      attr_reader :work

      # @param [Hydra::Works::Work] work
      def initialize(work)
        @work = work
      end

      # Update the visibility of the work to match the correct state of the embargo, then clear the embargo date, etc.
      # Saves the embargo and the work
      # @return [Hyrax::Embargo] the deactived embargo
      def destroy
        embargo = Hyrax::Queries.find_by(id: work.embargo_id)
        # If the embargo has lapsed, update the current visibility.
        work.assign_embargo_visibility(embargo)
        embargo.deactivate
        persister.save(resource: embargo)
        persister.save(resource: work)
        embargo
      end

      private

        def persister
          Valkyrie::MetadataAdapter.find(:indexing_persister).persister
        end
    end
  end
end

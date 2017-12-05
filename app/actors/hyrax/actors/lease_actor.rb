module Hyrax
  module Actors
    class LeaseActor
      attr_reader :work

      # @param [Hydra::Works::Work] work
      def initialize(work)
        @work = work
      end

      # Update the visibility of the work to match the correct state of the lease, then clear the lease date, etc.
      # Saves the lease and the work
      # @return [Hyrax::Lease] the deactived lease
      def destroy
        lease = Hyrax::Queries.find_by(id: work.lease_id)
        # If the lapsed has lapsed, update the current visibility.
        work.assign_lease_visibility(lease)
        lease.deactivate
        persister.save(resource: lease)
        persister.save(resource: work)
        lease
      end

      private

        def persister
          Valkyrie::MetadataAdapter.find(:indexing_persister).persister
        end
    end
  end
end

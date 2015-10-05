module CurationConcerns
  class LeaseActor
    attr_reader :work

    # @param [Hydra::Works::Work] work
    def initialize(work)
      @work = work
    end

    # Update the visibility of the work to match the correct state of the lease, then clear the lease date, etc.
    # Saves the lease and the work
    def destroy
      work.lease_visibility! # If the lease has lapsed, update the current visibility.
      work.deactivate_lease!
      work.lease.save!
      work.save!
    end
  end
end

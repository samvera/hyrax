module Hyrax
  # A work should be able to be filtered out of search results if it's inactive
  module Leasable
    extend ActiveSupport::Concern

    # Set the current visibility to match what is described in the lease.
    # @param lease [Hyrax::Lease] the lease visibility to copy to this work.
    def assign_lease_visibility(lease)
      return unless lease.lease_expiration_date
      self.visibility = if lease.active?
                          lease.visibility_during_lease
                        else
                          lease.visibility_after_lease
                        end
    end
  end
end

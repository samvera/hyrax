module Hyrax
  class LeaseService < RestrictionService
    class << self
      # Finds the existing lease or creates a new one.
      # @param resource [Valkyrie::Resource] typically a work or fileset. This will be mutated to set the lease_id
      # @param lease_params [Array] A tuple of arity 3 with the lease information
      # @return [Void]
      def apply_lease(resource:, lease_params:)
        lease = find_or_initialize_lease(resource)

        lease.lease_expiration_date = [DateTime.parse(lease_params[0]).in_time_zone]
        lease.visibility_during_lease = lease_params[1]
        lease.visibility_after_lease = lease_params[2]
        saved = persister.save(resource: lease)

        resource.lease_id = saved.id
        resource.assign_lease_visibility(lease)
      end

      def persister
        Valkyrie::MetadataAdapter.find(:indexing_persister).persister
      end
      private :persister

      def find_or_initialize_lease(resource)
        if resource.lease_id
          Hyrax::Queries.find_by(id: resource.lease_id)
        else
          Hyrax::Lease.new
        end
      end
      private :find_or_initialize_lease

      # Returns all assets with lease expiration date set to a date in the past
      def assets_with_expired_leases
        builder = Hyrax::ExpiredLeaseSearchBuilder.new(self)
        presenters(builder)
      end

      # Returns all assets with lease expiration date set
      #   (assumes that when lease visibility is applied to assets
      #    whose leases have expired, the lease expiration date will be removed from its metadata)
      def assets_under_lease
        builder = Hyrax::LeaseSearchBuilder.new(self)
        presenters(builder)
      end

      # Returns all assets that have had embargoes deactivated in the past.
      def assets_with_deactivated_leases
        builder = Hyrax::DeactivatedLeaseSearchBuilder.new(self)
        presenters(builder)
      end

      private

        def presenter_class
          Hyrax::LeasePresenter
        end
    end
  end
end

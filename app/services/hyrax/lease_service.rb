# frozen_string_literal: true
module Hyrax
  ##
  # Methods for Querying Repository to find Objects with leases
  class LeaseService < RestrictionService
    class << self
      # Returns all assets with lease expiration date set to a date in the past
      def assets_with_expired_enforced_leases
        builder = Hyrax::ExpiredLeaseSearchBuilder.new(self)
        presenters(builder)
      end
      alias assets_with_expired_leases assets_with_expired_enforced_leases

      ##
      # Returns all assets with leases that are currently enforced,
      # regardless of whether the leases are active or expired.
      #
      # @see Hyrax::LeaseManager
      def assets_with_enforced_leases
        builder = Hyrax::LeaseSearchBuilder.new(self)
        presenters(builder).select(&:enforced?)
      end
      alias assets_under_lease assets_with_enforced_leases

      # Returns all assets that have had embargoes deactivated in the past.
      def assets_with_deactivated_leases
        builder = Hyrax::DeactivatedLeaseSearchBuilder.new(self)
        presenters(builder)
      end

      def search_state_class
        nil
      end

      private

      def presenter_class
        Hyrax::LeasePresenter
      end
    end
  end
end

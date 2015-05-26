module CurationConcerns
  module LeaseService
    class << self
      # Returns all assets with lease expiration date set to a date in the past
      def assets_with_expired_leases
        ActiveFedora::Base.where('lease_expiration_date_dtsi:[* TO NOW]')
      end

      # Returns all assets with lease expiration date set
      #   (assumes that when lease visibility is applied to assets
      #    whose leases have expired, the lease expiration date will be removed from its metadata)
      def assets_under_lease
        ActiveFedora::Base.where('lease_expiration_date_dtsi:*')
      end

      # Returns all assets that have had embargoes deactivated in the past.
      def assets_with_deactivated_leases
        ActiveFedora::Base.where('lease_history_ssim:*')
      end
    end
  end
end


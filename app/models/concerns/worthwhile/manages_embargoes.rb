module Worthwhile
  module ManagesEmbargoes

    # Returns all assets with embargo release date set to a date in the past
    def assets_with_expired_embargoes
      ActiveFedora::Base.where('embargo_release_date_dtsi:[* TO NOW]')
    end

    # Returns all assets with embargo release date set
    #   (assumes that when lease visibility is applied to assets
    #    whose leases have expired, the lease expiration date will be removed from its metadata)
    def assets_under_embargo
      ActiveFedora::Base.where('embargo_release_date_dtsi:*')
    end

    # Returns all assets that have had embargoes deactivated in the past.
    def assets_with_deactivated_embargoes
      ActiveFedora::Base.where('embargo_history_ssim:*')
    end

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

    def apply_embargo_visibility(assets)
      response = {}
      Array(assets).each do |asset|
        response[asset.pid] = asset.apply_embargo_visibility!
      end
      response
    end

    def apply_lease_visibility(assets)
      response = {}
      Array(assets).each do |asset|
        response[asset.pid] = asset.apply_lease_visibility!
      end
      response
    end

  end
end

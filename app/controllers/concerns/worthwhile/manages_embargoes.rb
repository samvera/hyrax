module Worthwhile
  module ManagesEmbargoes
    extend ActiveSupport::Concern

    included do
      include Worthwhile::ThemedLayoutController
      with_themed_layout '1_column'

      attr_accessor :curation_concern
      helper_method :curation_concern
      helper_method :assets_under_embargo, :assets_with_expired_embargoes, :assets_with_deactivated_embargoes
      helper_method :assets_under_lease, :assets_with_expired_leases, :assets_with_deactivated_leases

      load_and_authorize_resource class: ActiveFedora::Base, instance_name: :curation_concern
    end


    def index
      authorize! :discover, :embargo
    end

    def edit
    end

    #
    # Methods for Querying Repository to find Embargoed Objects
    #

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

  end
end

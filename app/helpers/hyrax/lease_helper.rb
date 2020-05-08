module Hyrax
  module LeaseHelper
    def assets_with_expired_leases
      @assets_with_expired_leases ||= LeaseService.assets_with_expired_leases
    end

    def assets_under_lease
      @assets_under_lease ||= LeaseService.assets_under_lease
    end

    def assets_with_deactivated_leases
      @assets_with_deactivated_leases ||= LeaseService.assets_with_deactivated_leases
    end

    ##
    # @since 3.0.0
    #
    # @param [Valkyrie::Resource, ActiveFedora::Base] resource
    #
    # @return [Boolean] whether the resource has an lease that is currently
    #   enforced (regardless of whether it has expired)
    def lease_enforced?(resource)
      case resource
      when Hydra::AccessControls::Embargoable
        !resource.lease_expiration_date.nil?
      when Valkyrie::ChangeSet
        Hyrax::LeaseManager.new(resource: resource.model).enforced?
      else
        Hyrax::LeaseManager.new(resource: resource).enforced?
      end
    end
  end
end

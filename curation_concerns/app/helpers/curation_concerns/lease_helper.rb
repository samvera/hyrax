module CurationConcerns
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
  end
end

# frozen_string_literal: true
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
    #
    # @note Hyrax::Forms::Failedsubmissionformwrapper is a place
    #   holder until we switch to Valkyrie::ChangeSet instead of Form
    #   objects
    def lease_enforced?(resource)
      # This is a guard; from the UI rendering perspective, there's no
      # active lease enforcement until the object is saved.
      return false unless resource.persisted?

      case resource
      when Hydra::AccessControls::Embargoable
        !resource.lease_expiration_date.nil?
      when HydraEditor::Form, Hyrax::Forms::FailedSubmissionFormWrapper
        lease_enforced?(resource.model)
      when Valkyrie::ChangeSet
        Hyrax::LeaseManager.new(resource: resource.model).enforced?
      else
        Hyrax::LeaseManager.new(resource: resource).enforced?
      end
    end

    ##
    # @since 3.5.0
    #
    # @param [#lease_history, #lease] resource
    #
    # @return [Array]
    def lease_history(resource)
      resource.try(:lease_history) ||
        Array(resource.lease&.lease_history)
    end
  end
end

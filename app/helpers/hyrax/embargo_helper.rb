# frozen_string_literal: true
module Hyrax
  module EmbargoHelper
    def assets_with_expired_embargoes
      @assets_with_expired_embargoes ||= EmbargoService.assets_with_expired_embargoes
    end

    def assets_under_embargo
      @assets_under_embargo ||= EmbargoService.assets_under_embargo
    end

    def assets_with_deactivated_embargoes
      @assets_with_deactivated_embargoes ||= EmbargoService.assets_with_deactivated_embargoes
    end

    ##
    # @since 3.0.0
    #
    # @param [Valkyrie::Resource, ActiveFedora::Base] resource
    #
    # @return [Boolean] whether the resource has an embargo that is currently
    #   enforced (regardless of whether it has expired)
    #
    # @note Hyrax::Forms::Failedsubmissionformwrapper is a place
    #   holder until we switch to Valkyrie::ChangeSet instead of Form
    #   objects
    def embargo_enforced?(resource)
      # This is a guard; from the UI rendering perspective, there's no
      # active embargo enforcement until the object is saved.
      return false unless resource.persisted?

      case resource
      when Hydra::AccessControls::Embargoable
        !resource.embargo_release_date.nil?
      when HydraEditor::Form, Hyrax::Forms::FailedSubmissionFormWrapper
        embargo_enforced?(resource.model)
      when Valkyrie::ChangeSet
        Hyrax::EmbargoManager.new(resource: resource.model).enforced?
      else
        Hyrax::EmbargoManager.new(resource: resource).enforced?
      end
    end

    ##
    # @since 3.5.0
    #
    # @param [#embargo_history, #embargo] resource
    #
    # @return [Array]
    def embargo_history(resource)
      resource.try(:embargo_history) ||
        Array(resource.embargo&.embargo_history)
    end
  end
end

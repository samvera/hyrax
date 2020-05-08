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
    def embargo_enforced?(resource)
      case resource
      when Hydra::AccessControls::Embargoable
        !resource.embargo_release_date.nil?
      when Valkyrie::ChangeSet
        Hyrax::EmbargoManager.new(resource: resource.model).enforced?

      else
        Hyrax::EmbargoManager.new(resource: resource).enforced?
      end
    end
  end
end

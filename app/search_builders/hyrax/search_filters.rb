# frozen_string_literal: true

module Hyrax
  module SearchFilters
    extend ActiveSupport::Concern
    include Hyrax::FilterByType
    include FilterSuppressed

    # Override Hydra::AccessControlsEnforcement (or Hydra::PolicyAwareAccessControlsEnforcement)
    # Allows admin users to see everything (don't apply any gated_discovery_filters for those users)
    def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
      return [] if ability.admin?
      super
    end
  end
end

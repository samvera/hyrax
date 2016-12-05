module CurationConcerns::SearchFilters
  extend ActiveSupport::Concern
  include CurationConcerns::FilterByType
  include CurationConcerns::FilterSuppressed

  # Override Hydra::AccessControlsEnforcement (or Hydra::PolicyAwareAccessControlsEnforcement)
  # Allows admin users to see everything (don't apply any gated_discovery_filters for those users)
  def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
    return [] if ability.admin?
    super
  end

  # show only files with edit permissions in lib/hydra/access_controls_enforcement.rb apply_gated_discovery
  def discovery_permissions
    return ['edit'] if blacklight_params[:works] == 'mine'
    super
  end
end

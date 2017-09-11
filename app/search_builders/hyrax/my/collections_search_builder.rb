# Added to allow for the My controller to show only collections and admin sets
# that I have edit access to.
class Hyrax::My::CollectionsSearchBuilder < ::SearchBuilder
  include Hyrax::FilterByType

  self.solr_access_filters_logic += [:apply_admin_set_management_permissions]

  # This overrides the models in FilterByType
  # @return [Array<Class>] a list of classes to include
  def models
    [::AdminSet, ::Collection]
  end

  # This combines with the `:add_access_controls_to_solr_params` filter
  # to only discover itmes in which the user has edit access.
  def discovery_permissions
    @discovery_permissions ||= %w[edit]
  end

  # Include all admin sets the user can manage.
  # @return [Array{String}] values are lucence syntax term queries suitable for :fq
  def apply_admin_set_management_permissions(permission_types, ability = current_ability)
    admin_set_ids = source_ids_for_management
    return [] if admin_set_ids.empty?
    ["{!terms f=id}#{source_ids_for_management.join(',')}"]
  end

  delegate :source_ids_for_management, to: :current_ability
  private :source_ids_for_management
end

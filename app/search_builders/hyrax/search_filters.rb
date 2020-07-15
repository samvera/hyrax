# frozen_string_literal: true
module Hyrax
  module SearchFilters
    extend ActiveSupport::Concern
    include Hyrax::FilterByType
    include FilterSuppressed

    # TODO: move this to Hydra::AccessControlsEnforcement
    # @param access [String] what access level to set. Either 'read' or 'edit'
    # @return [SearchBuilder]
    def with_access(access)
      @discovery_permissions = Array.wrap(access)
      self
    end

    # This method will return true if the user has an appoval role, and false otherwise.
    # This is used to for approvers to gain access to a private work.  If this check were not done, the approver
    # would not be able to access private works.
    def user_approver?
      approving_role = Sipity::Role.find_by(name: Hyrax::RoleRegistry::APPROVING)
      return false unless approving_role
      Hyrax::Workflow::PermissionQuery.scope_processing_agents_for(user: current_ability.current_user).any? do |agent|
        agent.workflow_responsibilities.joins(:workflow_role)
             .where('sipity_workflow_roles.role_id' => approving_role.id).any?
      end
    end

    # Override Hydra::AccessControlsEnforcement (or Hydra::PolicyAwareAccessControlsEnforcement)
    # Allows admin users to see everything (don't apply any gated_discovery_filters for those users)
    def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
      return [] if user_approver?
      return [] if ability.admin?
      super
    end

    private

    # TODO: could this be moved to Blacklight::AccessControls::Enforcement?
    def current_user_key
      current_user.user_key
    end

    # TODO: could this be moved to Blacklight::AccessControls::Enforcement?
    def current_user
      scope.current_user
    end
  end
end

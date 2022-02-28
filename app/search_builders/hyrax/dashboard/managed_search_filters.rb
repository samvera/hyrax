# frozen_string_literal: true
module Hyrax
  module Dashboard
    module ManagedSearchFilters
      extend ActiveSupport::Concern

      # This includes collection/admin the user can manage and view.
      def discovery_permissions
        @discovery_permissions ||= %w[edit read]
      end

      # Override to exclude 'public' and 'registered' groups from read access.
      def apply_group_permissions(permission_types, ability = current_ability)
        search_terms = add_managing_role_search_filter(ability: ability)
        groups = ability.user_groups
        return search_terms if groups.empty?
        permission_types.each do |type|
          field = solr_field_for(type, 'group')
          delete_groups = [::Ability.public_group_name, ::Ability.registered_group_name]
          user_groups = type == 'read' ? groups - delete_groups : groups
          next if user_groups.empty?
          # parens required to properly OR the clauses together:
          search_terms << "({!terms f=#{field}}#{user_groups.join(',')})"
        end
        search_terms
      end

      # Look for a user's managing role and add filters for all admin sets that have permission
      # templates that include managing roles.
      #
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      def add_managing_role_search_filter(ability:, search_terms: [])
        search_terms ||= []
        # Look for managing role assignement
        managing_role = Sipity::Role.find_by(name: Hyrax::RoleRegistry::MANAGING)
        return search_terms if managing_role.blank?
        agent = ability.current_user.to_sipity_agent
        return search_terms if agent.workflow_responsibilities.blank?
        managing_workflow_roles = []
        agent.workflow_responsibilities.each do |workflow_responsibility|
          wfr = Sipity::WorkflowRole.find_by(id: workflow_responsibility.workflow_role_id)
          managing_workflow_roles << wfr if wfr.role_id == managing_role.id
        end
        return search_terms if managing_workflow_roles.empty?
        # if the user has managing responsibilties, then look up the associated admin set ids
        admin_set_ids = managing_workflow_roles.map do |wfr|
          wf = Sipity::Workflow.find_by(id: wfr.workflow_id)
          pt = Hyrax::PermissionTemplate.find_by(id: wf.permission_template_id)
          pt.source_id
        end
        admin_set_ids.uniq!
        # create search terms for works that are in managed admin sets
        admin_set_ids.each do |id|
          search_terms << "isPartOf_ssim:#{id}"
        end
        search_terms
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end

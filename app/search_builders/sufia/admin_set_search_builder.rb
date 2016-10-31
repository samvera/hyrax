module Sufia
  ### Allows :deposit as a valid type
  class AdminSetSearchBuilder < CurationConcerns::AdminSetSearchBuilder
    # We're going to check the permission_templates
    def gated_discovery_filters
      return super if @access != :deposit
      ["{!terms f=id}#{admin_set_ids.join(',')}"]
    end

    private

      def admin_set_ids
        PermissionTemplateAccess.joins(:permission_template)
                                .where(agent_type: 'user',
                                       agent_id: user,
                                       access: ['deposit', 'manage'])
                                .pluck('DISTINCT admin_set_id')
      end

      def user
        current_ability.current_user.user_key
      end
  end
end

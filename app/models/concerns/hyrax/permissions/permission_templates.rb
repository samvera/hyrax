module Hyrax
  module Permissions
    module PermissionTemplates
      extend ActiveSupport::Concern
      
        # @api public
        # Retrieve the permission template for this collection.
        # @return [Hyrax::PermissionTemplate]
        # @raise [ActiveRecord::RecordNotFound]
        def permission_template
          Hyrax::PermissionTemplate.find_by!(source_id: id)
        end

        private

          def permission_template_edit_users
            permission_template.agent_ids_for(access: 'manage', agent_type: 'user')
          end

          def permission_template_edit_groups
            permission_template.agent_ids_for(access: 'manage', agent_type: 'group')
          end

          def permission_template_read_users
            (permission_template.agent_ids_for(access: 'view', agent_type: 'user') +
              permission_template.agent_ids_for(access: 'deposit', agent_type: 'user')).uniq
          end

          def permission_template_read_groups
            (permission_template.agent_ids_for(access: 'view', agent_type: 'group') +
              permission_template.agent_ids_for(access: 'deposit', agent_type: 'group')).uniq -
              [::Ability.registered_group_name, ::Ability.public_group_name]
          end

          def destroy_permission_template
            permission_template.destroy
          rescue ActiveRecord::RecordNotFound
            true
          end
    end
  end
end
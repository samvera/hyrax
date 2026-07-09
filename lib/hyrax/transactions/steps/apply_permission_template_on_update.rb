# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transaction` step that applies a permission template to a work
      # when its admin set has changed during an update.
      #
      # Removes grants from the old admin set's permission template that are not
      # present in the new template, then applies the new template's grants.
      # Manually added permissions and the depositor's access are preserved.
      #
      # @since 5.1.0
      class ApplyPermissionTemplateOnUpdate
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::Work] object
        #
        # @return [Dry::Monads::Result]
        def call(object)
          return Success(object) unless object.respond_to?(:previous_admin_set_id)

          old_template = Hyrax::PermissionTemplate.find_by(source_id: object.previous_admin_set_id)
          new_template = Hyrax::PermissionTemplate.find_by(source_id: object.admin_set_id)

          remove_old_grants(object, old_template, new_template) if old_template

          if new_template
            Hyrax::PermissionTemplateApplicator.apply(new_template).to(model: object)
          else
            Hyrax.logger.warn("At update time, #{object} doesn't have a " \
                              "PermissionTemplate for new AdministrativeSet " \
                              "#{object.admin_set_id}. Continuing without " \
                              "applying permissions.")
          end

          Success(object)
        end

        private

        def remove_old_grants(object, old_template, new_template)
          new_agents = agents_from_template(new_template)

          object.edit_groups = object.edit_groups.to_a - (old_template.agent_ids_for(agent_type: 'group', access: 'manage') - new_agents[:manage_groups])
          object.edit_users  = object.edit_users.to_a  - (old_template.agent_ids_for(agent_type: 'user',  access: 'manage') - new_agents[:manage_users])
          object.read_groups = object.read_groups.to_a - (old_template.agent_ids_for(agent_type: 'group', access: 'view')   - new_agents[:view_groups])
          object.read_users  = object.read_users.to_a  - (old_template.agent_ids_for(agent_type: 'user',  access: 'view')   - new_agents[:view_users])
        end

        def agents_from_template(template)
          return { manage_groups: [], manage_users: [], view_groups: [], view_users: [] } if template.nil?

          {
            manage_groups: template.agent_ids_for(agent_type: 'group', access: 'manage').to_a,
            manage_users: template.agent_ids_for(agent_type: 'user', access: 'manage').to_a,
            view_groups: template.agent_ids_for(agent_type: 'group', access: 'view').to_a,
            view_users: template.agent_ids_for(agent_type: 'user', access: 'view').to_a
          }
        end
      end
    end
  end
end

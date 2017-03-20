module Hyrax
  # Responsible for "applying" the various edit and read attributes to the given curation concern.
  # @see Hyrax::AdminSetService for release_date interaction
  class ApplyPermissionTemplateActor < Hyrax::Actors::AbstractActor
    def create(attributes)
      add_edit_users(attributes)
      next_actor.create(attributes)
    end

    protected

      def add_edit_users(attributes)
        return unless attributes[:admin_set_id].present?
        template = Hyrax::PermissionTemplate.find_by!(admin_set_id: attributes[:admin_set_id])
        curation_concern.edit_users += template.agent_ids_for(agent_type: 'user', access: 'manage')
        curation_concern.edit_groups += template.agent_ids_for(agent_type: 'group', access: 'manage')
        curation_concern.read_users += template.agent_ids_for(agent_type: 'user', access: 'view')
        curation_concern.read_groups += template.agent_ids_for(agent_type: 'group', access: 'view')
      end
  end
end

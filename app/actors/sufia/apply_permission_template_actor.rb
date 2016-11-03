module Sufia
  class ApplyPermissionTemplateActor < CurationConcerns::Actors::AbstractActor
    def create(attributes)
      add_edit_users(attributes)
      next_actor.create(attributes)
    end

    protected

      def add_edit_users(attributes)
        return unless attributes[:admin_set_id].present?
        template = Sufia::PermissionTemplate.find_by!(admin_set_id: attributes[:admin_set_id])
        curation_concern.edit_users = template.access_grants.where(agent_type: 'user', access: 'manage').pluck(:agent_id)
        curation_concern.edit_groups = template.access_grants.where(agent_type: 'group', access: 'manage').pluck(:agent_id)
        curation_concern.read_users = template.access_grants.where(agent_type: 'user', access: 'view').pluck(:agent_id)
        curation_concern.read_groups = template.access_grants.where(agent_type: 'group', access: 'view').pluck(:agent_id)
      end
  end
end

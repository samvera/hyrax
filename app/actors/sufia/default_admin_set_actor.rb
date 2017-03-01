module Sufia
  # Ensures that the default AdminSet id is set if this form doesn't have
  # an admin_set_id provided. This should come before the
  # CurationConcerns::Actors::InitializeWorkflowActor, so that the correct
  # workflow can be kicked off.
  class DefaultAdminSetActor < CurationConcerns::Actors::AbstractActor
    def create(attributes)
      ensure_admin_set_attribute!(attributes)
      next_actor.create(attributes)
    end

    def update(attributes)
      ensure_admin_set_attribute!(attributes)
      next_actor.update(attributes)
    end

    private

      def ensure_admin_set_attribute!(attributes)
        if attributes[:admin_set_id].present?
          ensure_permission_template!(admin_set_id: attributes[:admin_set_id])
        else
          attributes[:admin_set_id] = default_admin_set_id
        end
      end

      def ensure_permission_template!(admin_set_id:)
        Sufia::PermissionTemplate.find_or_create_by!(admin_set_id: admin_set_id)
      end

      DEFAULT_ID = 'admin_set/default'.freeze

      def default_admin_set_id
        create_default_admin_set unless default_exists?
        DEFAULT_ID
      end

      def default_exists?
        AdminSet.exists?(DEFAULT_ID)
      end

      # Creates the default AdminSet and an associated PermissionTemplate with workflow
      def create_default_admin_set
        AdminSet.create!(id: DEFAULT_ID, title: ['Default Admin Set']).tap do |_as|
          PermissionTemplate.create!(admin_set_id: DEFAULT_ID, workflow_name: 'default')
        end
      end
  end
end

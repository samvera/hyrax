module Hyrax
  # Ensures that the default AdminSet id is set if this form doesn't have
  # an admin_set_id provided. This should come before the
  # Hyrax::Actors::InitializeWorkflowActor, so that the correct
  # workflow can be kicked off.
  #
  # @note Creates AdminSet, Hyrax::PermissionTemplate, Sipity::Workflow (with activation)
  class DefaultAdminSetActor < Hyrax::Actors::AbstractActor
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
        return if attributes[:admin_set_id].present?
        attributes[:admin_set_id] = default_admin_set_id
      end

      def default_admin_set_id
        create_default_admin_set unless default_exists?
        AdminSet::DEFAULT_ID
      end

      def default_exists?
        AdminSet.exists?(AdminSet::DEFAULT_ID)
      end

      # Creates the default AdminSet and an associated PermissionTemplate with workflow and activates the default.
      #
      # rubocop:disable Lint/HandleExceptions
      def create_default_admin_set
        # Wrapping in a transaction, leveraging the fact that database entries can be transactional.
        # If we first create the admin set then step through the Hyrax::PermissionTemplate
        Hyrax::PermissionTemplate.transaction do
          Sipity::Workflow.transaction do
            Hyrax::PermissionTemplate.create!(admin_set_id: AdminSet::DEFAULT_ID) do |permission_template|
              Hyrax::Workflow::WorkflowImporter.load_workflow_for(permission_template: permission_template)
              Sipity::Workflow.activate!(permission_template: permission_template, workflow_name: Hyrax.config.default_active_workflow_name)
            end
            AdminSet.create!(id: AdminSet::DEFAULT_ID, title: ['Default Admin Set'])
          end
        end
      rescue ActiveFedora::IllegalOperation
        # It is possible that another thread created the AdminSet just before this method
        # was called, so ActiveFedora will raise IllegalOperation. In this case we can safely
        # ignore the error.
      end
    # rubocop:enable Lint/HandleExceptions
  end
end

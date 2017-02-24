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
      def create_default_admin_set
        default_admin_set = AdminSet.new(id: AdminSet::DEFAULT_ID, title: ['Default Admin Set'])
        begin
          Hyrax::AdminSetCreateService.call(default_admin_set, user)
        rescue ActiveFedora::IllegalOperation
          # It is possible that another thread created the AdminSet just before this method
          # was called, so ActiveFedora will raise IllegalOperation. In this case we can safely
          # ignore the error.
          Rails.logger.debug("AdminSet ID=#{default_admin_set.id} may or may not have been created due to threading issues.")
        end
      end
  end
end

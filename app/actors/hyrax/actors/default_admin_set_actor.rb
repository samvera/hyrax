module Hyrax
  module Actors
    # Ensures that the default AdminSet id is set if this form doesn't have
    # an admin_set_id provided. This should come before the
    # Hyrax::Actors::InitializeWorkflowActor, so that the correct
    # workflow can be kicked off.
    #
    # @note Creates AdminSet, Hyrax::PermissionTemplate, Sipity::Workflow (with activation)
    class DefaultAdminSetActor < Hyrax::Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        ensure_admin_set_attribute!(env.attributes)
        next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        ensure_admin_set_attribute!(env.attributes)
        next_actor.update(env)
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
          Hyrax::PermissionTemplate.find_by(admin_set_id: admin_set_id) || create_permission_template!(admin_set_id: admin_set_id)
        end

        def default_admin_set_id
          AdminSet.find_or_create_default_admin_set_id
        end

        # Creates a Hyrax::PermissionTemplate for the given AdminSet
        def create_permission_template!(admin_set_id:)
          Hyrax::PermissionTemplate.create!(admin_set_id: admin_set_id)
        end
    end
  end
end

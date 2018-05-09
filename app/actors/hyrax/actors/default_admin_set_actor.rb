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
        ensure_admin_set_attribute!(env)
        next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        ensure_admin_set_attribute!(env)
        next_actor.update(env)
      end

      private

        def ensure_admin_set_attribute!(env)
          if env.attributes[:admin_set_id].present?
            ensure_permission_template!(admin_set_id: env.attributes[:admin_set_id])
          elsif env.curation_concern.admin_set_id.present?
            env.attributes[:admin_set_id] = env.curation_concern.admin_set_id
            ensure_permission_template!(admin_set_id: env.attributes[:admin_set_id])
          else
            env.attributes[:admin_set_id] = default_admin_set_id
          end
        end

        def ensure_permission_template!(admin_set_id:)
          Hyrax::PermissionTemplate.find_by(source_id: admin_set_id) || create_permission_template!(source_id: admin_set_id)
        end

        def default_admin_set_id
          AdminSet.find_or_create_default_admin_set_id
        end

        # Creates a Hyrax::PermissionTemplate for the given AdminSet
        def create_permission_template!(source_id:)
          Hyrax::PermissionTemplate.create!(source_id: source_id)
        end
    end
  end
end

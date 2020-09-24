# frozen_string_literal: true
module Hyrax
  module Actors
    # Ensures that the default AdminSet id is set if this form doesn't have
    # an admin_set_id provided. This should come before the
    # Hyrax::Actors::InitializeWorkflowActor, so that the correct
    # workflow can be kicked off.
    #
    # @see Hyrax::EnsureWellFormedAdminSetService
    #
    # @note Creates AdminSet, Hyrax::PermissionTemplate, Sipity::Workflow (with activation)
    class DefaultAdminSetActor < Hyrax::Actors::AbstractActor
      # Hyrax provides a service that ensures well formed admin sets.
      # It is possible that downstream implementers might seek to
      # override this behavior.  The class attribute provicdes a means
      # to override that behavior.
      class_attribute :ensure_well_formed_admin_set_service
      self.ensure_well_formed_admin_set_service = Hyrax::EnsureWellFormedAdminSetService

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

      # This method:
      #
      # - ensures that the env.attributes[:admin_set_id] is set
      # - ensures that the permission template for the admin set is correct
      def ensure_admin_set_attribute!(env)
        # These logical hoops copy the prior behavior of the code;
        # With a small logical caveat.  If the given curation_concern
        # has an admin_set_id, we now verify that that admin set is
        # well formed.
        given_admin_set_id = env.attributes[:admin_set_id].presence || env.curation_concern.admin_set_id.presence
        admin_set_id = ensure_well_formed_admin_set_service.call(admin_set_id: given_admin_set_id)
        env.attributes[:admin_set_id] = given_admin_set_id || admin_set_id
      end
    end
  end
end

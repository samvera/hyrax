module Hyrax
  module Admin
    class PermissionTemplateAccessesController < ApplicationController
      load_and_authorize_resource class: 'Hyrax::PermissionTemplateAccess'

      def destroy
        ActiveRecord::Base.transaction do
          @permission_template_access.destroy if valid_delete?
          remove_access!
        end

        if @permission_template_access.destroyed?
          after_destroy_success
        else
          after_destroy_error
        end
      end

      private

        # This is a controller validation rather than a model validation
        # because we don't want to prevent the ability to remove the whole
        # PermissionTemplate and all of its associated PermissionTemplateAccesses
        # @return [Boolean] true if it's valid
        def valid_delete?
          return true unless @permission_template_access.admin_group?
          @permission_template_access.errors[:base] <<
            t('hyrax.admin.admin_sets.form.permission_destroy_errors.admin_group')
          false
        end

        def after_destroy_success
          redirect_to hyrax.edit_admin_admin_set_path(admin_set_id,
                                                      anchor: 'participants'),
                      notice: t('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices')
        end

        def after_destroy_error
          redirect_to hyrax.edit_admin_admin_set_path(admin_set_id,
                                                      anchor: 'participants'),
                      alert: @permission_template_access.errors.full_messages.to_sentence
        end

        # @return [String] the identifier for the AdminSet for the currently loaded resource
        def admin_set_id
          @admin_set_id ||= @permission_template_access.permission_template.admin_set_id
        end

        def remove_access!
          Forms::PermissionTemplateForm.new(@permission_template_access.permission_template)
                                       .remove_access!(@permission_template_access)
        end
    end
  end
end

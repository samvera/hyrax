module Hyrax
  module Admin
    class PermissionTemplateAccessesController < ApplicationController
      load_and_authorize_resource class: 'Hyrax::PermissionTemplateAccess'

      def destroy
        @permission_template_access.destroy
        update_admin_set if @permission_template_access.manage?

        redirect_to hyrax.edit_admin_admin_set_path(admin_set_id,
                                                    anchor: 'participants'),
                    notice: translate('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices')
      end

      private

        # @return [String] the identifier for the AdminSet for the currently loaded resource
        def admin_set_id
          @admin_set_id ||= @permission_template_access.permission_template.admin_set_id
        end

        def update_admin_set
          AdminSet.find(admin_set_id).update_access_controls!
        end
    end
  end
end

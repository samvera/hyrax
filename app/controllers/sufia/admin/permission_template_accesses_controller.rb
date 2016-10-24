module Sufia
  module Admin
    class PermissionTemplateAccessesController < ApplicationController
      load_and_authorize_resource class: 'Sufia::PermissionTemplateAccess'

      def destroy
        @permission_template_access.destroy

        redirect_to sufia.edit_admin_admin_set_path(@permission_template_access.permission_template.admin_set_id,
                                                    anchor: 'participants'),
                    notice: 'Permissions updated'
      end
    end
  end
end

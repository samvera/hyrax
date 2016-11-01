module Sufia
  module Admin
    class PermissionTemplatesController < ApplicationController
      before_action :load_template_for_admin_set

      def update
        authorize! :update, @permission_template
        @permission_template.update(update_params)
        redirect_to sufia.edit_admin_admin_set_path(params[:admin_set_id], anchor: 'participants'),
                    notice: 'Permissions updated'
      end

      private

        # This sets the @permission_template so that CanCanCan doesn't have to.
        def load_template_for_admin_set
          @permission_template = Sufia::PermissionTemplate.find_by(admin_set_id: params[:admin_set_id])
        end

        def update_params
          params.require(:sufia_permission_template)
                .permit(access_grants_attributes: [:access, :agent_id, :agent_type, :id])
        end
    end
  end
end

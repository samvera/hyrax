module Hyrax
  module Admin
    class PermissionTemplatesController < ApplicationController
      load_and_authorize_resource find_by: 'admin_set_id',
                                  id_param: 'admin_set_id',
                                  class: 'Hyrax::PermissionTemplate'

      def update
        Forms::PermissionTemplateForm.new(@permission_template).update(update_params)
        # Ensure we redirect to currently active tab with the appropriate notice
        current_tab = current_tab_selector
        redirect_to hyrax.edit_admin_admin_set_path(params[:admin_set_id], anchor: current_tab), notice: I18n.t(current_tab, scope: 'hyrax.admin.admin_sets.form.permission_update_notices')
      end

      private

        def update_params
          params.require(:permission_template)
                .permit(:release_date, :release_period, :release_varies, :release_embargo, :visibility, :workflow_name,
                        access_grants_attributes: [:access, :agent_id, :agent_type, :id])
        end

        def current_tab_selector
          return 'participants' if params[:permission_template][:access_grants_attributes].present?
          return 'workflow' if params[:permission_template][:workflow_name].present?
          'visibility'
        end
    end
  end
end

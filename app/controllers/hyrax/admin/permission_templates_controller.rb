module Hyrax
  module Admin
    class PermissionTemplatesController < ApplicationController
      load_and_authorize_resource find_by: 'admin_set_id',
                                  id_param: 'admin_set_id',
                                  class: 'Hyrax::PermissionTemplate'

      def update
        form.update(update_params)
        # Ensure we redirect to currently active tab with the appropriate notice
        redirect_to edit_admin_admin_set_path(params[:admin_set_id], anchor: current_tab),
                    notice: translate(current_tab, scope: 'hyrax.admin.admin_sets.form.permission_update_notices')
      end

      private

        def form
          Forms::PermissionTemplateForm.new(@permission_template)
        end

        def update_params
          params.require(:permission_template)
                .permit(:release_date, :release_period, :release_varies, :release_embargo, :visibility, :workflow_id,
                        access_grants_attributes: [:access, :agent_id, :agent_type, :id])
        end

        # @return [String] the name of the current UI tab to show
        def current_tab
          pt = params[:permission_template]
          @current_tab ||= if pt[:access_grants_attributes].present?
                             'participants'
                           elsif pt[:workflow_name].present?
                             'workflow'
                           else
                             'visibility'
                           end
        end
    end
  end
end

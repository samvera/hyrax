module Hyrax
  module Admin
    class PermissionTemplatesController < ApplicationController
      load_and_authorize_resource find_by: 'admin_set_id',
                                  id_param: 'admin_set_id',
                                  class: 'Hyrax::PermissionTemplate'

      # Override the default prefixes so that we use the collection partals.
      def self.local_prefixes
        ["hyrax/admin/admin_sets"]
      end

      def update
        update_info = form.update(update_params)
        if update_info[:updated] == true # Ensure we redirect to currently active tab with the appropriate notice
          redirect_to(edit_admin_admin_set_path(params[:admin_set_id], anchor: current_tab),
                      notice: translate(update_info[:content_tab], scope: 'hyrax.admin.admin_sets.form.permission_update_notices'))
        else
          # When we have invalid data, we are redirecting because to render, we need to set an AdminSetForm
          # (because we are rendering admin set forms)
          # TODO: [Jeremy Friesen says: We need to better consolidate the form logic of admin sets and permission templates
          redirect_to(edit_admin_admin_set_path(params[:admin_set_id], anchor: current_tab),
                      alert: translate(update_info[:error_code], scope: 'hyrax.admin.admin_sets.form.permission_update_errors'))
        end
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
                           elsif pt[:workflow_id].present?
                             'workflow'
                           else
                             'visibility'
                           end
        end
    end
  end
end

# frozen_string_literal: true
module Hyrax
  module Admin
    class PermissionTemplatesController < ApplicationController
      before_action :find_permission_template
      authorize_resource class: 'Hyrax::PermissionTemplate', instance_name: :permission_template

      def update
        update_info = form.update(update_params)
        if update_info[:updated] == true # Ensure we redirect to currently active tab with the appropriate notice
          redirect_to_edit_path(update_info)
        else
          redirect_to_edit_path_with_error(update_info)
        end
      end

      private

      # Override the default prefixes so that we use the correct partials.
      def _prefixes
        if admin_set?
          @_prefixes ||= super + ['hyrax/admin/admin_sets']
        elsif collection?
          @_prefixes ||= super + ['hyrax/dashboard/collections']
        end
      end

      # We need to do this manually instead of using load_and_authorize_resource
      # because the id we are looking for is different when using an admin set vs. collection
      def find_permission_template
        if admin_set?
          @permission_template = PermissionTemplate.find_by(source_id: params[:admin_set_id])
        elsif collection?
          @permission_template = PermissionTemplate.find_by(source_id: params[:collection_id])
        end
      end

      def redirect_to_edit_path(update_info)
        if admin_set?
          redirect_to(edit_admin_admin_set_path(params[:admin_set_id], anchor: current_tab),
                      notice: translate(update_info[:content_tab], scope: 'hyrax.admin.admin_sets.form.permission_update_notices'))
        elsif collection?
          redirect_to(edit_dashboard_collection_path(params[:collection_id], anchor: current_tab),
                      notice: translate(update_info[:content_tab], scope: 'hyrax.dashboard.collections.form.permission_update_notices'))
        end
      end

      def redirect_to_edit_path_with_error(update_info)
        # When we have invalid data, we are redirecting because to render, we need to set an AdminSetForm
        # (because we are rendering admin set forms)
        # TODO: [Jeremy Friesen says: We need to better consolidate the form logic of admin sets and permission templates
        if admin_set?
          redirect_to(edit_admin_admin_set_path(params[:admin_set_id], anchor: current_tab),
                      alert: translate(update_info[:error_code], scope: 'hyrax.admin.admin_sets.form.permission_update_errors'))
        elsif collection?
          redirect_to(edit_dashboard_collection_path(params[:collection_id], anchor: current_tab),
                      alert: translate(update_info[:error_code], scope: 'hyrax.dashboard.collections.form.permission_update_errors'))
        end
      end

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
        if collection?
          @current_tab ||= 'sharing'
        else
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

      def admin_set?
        params['admin_set_id'].present?
      end

      def collection?
        params['collection_id'].present?
      end
    end
  end
end

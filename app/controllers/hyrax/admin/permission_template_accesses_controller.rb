module Hyrax
  module Admin
    class PermissionTemplateAccessesController < ApplicationController
      load_and_authorize_resource class: 'Hyrax::PermissionTemplateAccess'

      def destroy
        ActiveRecord::Base.transaction do
          @permission_template_access.destroy
          update_access(manage_changed: @permission_template_access.manage?)
        end

        if @permission_template_access.destroyed?
          redirect_to_edit_path
        else
          redirect_to_edit_path_with_error
        end
      end

      private

        # @return [String] the identifier for the AdminSet for the currently loaded resource
        def source_id
          @source_id ||= @permission_template_access.permission_template.source_id
        end

        def update_access(manage_changed:)
          Forms::PermissionTemplateForm.new(@permission_template_access.permission_template).update_access(manage_changed: manage_changed)
        end

        def redirect_to_edit_path
          if source_type == 'admin_set'
            redirect_to hyrax.edit_admin_admin_set_path(source_id,
                                                        anchor: 'participants'),
                        notice: translate('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices')
          elsif source_type == 'collection'
            redirect_to hyrax.edit_dashboard_collection_path(source_id,
                                                             anchor: 'sharing'),
                        notice: translate('sharing', scope: 'hyrax.dashboard.collections.form.permission_update_notices')
          end
        end

        def redirect_to_edit_path_with_error
          if source_type == 'admin_set'
            redirect_to hyrax.edit_admin_admin_set_path(source_id,
                                                        anchor: 'participants'),
                        alert: @permission_template_access.errors.full_messages.to_sentence
          elsif source_type == 'collection'
            redirect_to hyrax.edit_dashboard_collection_path(source_id,
                                                             anchor: 'sharing'),
                        alert: @permission_template_access.errors.full_messages.to_sentence
          end
        end

        def source_type
          Hyrax::PermissionTemplate.find(@permission_template_access.permission_template_id).source_type
        end
    end
  end
end

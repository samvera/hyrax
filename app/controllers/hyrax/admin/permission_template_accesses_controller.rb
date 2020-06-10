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

      def update_access(manage_changed:)
        permission_template_form.update_access(manage_changed: manage_changed)
      end

      def after_destroy_success
        if source.admin_set?
          redirect_to hyrax.edit_admin_admin_set_path(source_id,
                                                      anchor: 'participants'),
                      notice: translate('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices')
        elsif source.collection?
          redirect_to hyrax.edit_dashboard_collection_path(source_id,
                                                           anchor: 'sharing'),
                      notice: translate('sharing', scope: 'hyrax.dashboard.collections.form.permission_update_notices')
        end
      end

      def after_destroy_error
        if source.admin_set?
          redirect_to hyrax.edit_admin_admin_set_path(source_id,
                                                      anchor: 'participants'),
                      alert: @permission_template_access.errors.full_messages.to_sentence
        elsif source.collection?
          redirect_to hyrax.edit_dashboard_collection_path(source_id,
                                                           anchor: 'sharing'),
                      alert: @permission_template_access.errors.full_messages.to_sentence
        end
      end

      delegate :source_id, to: :permission_template

      def source
        @source ||= ::SolrDocument.find(source_id)
      end

      def remove_access!
        permission_template_form.remove_access!(@permission_template_access)
      end

      def permission_template_form
        @permission_template_form ||= Forms::PermissionTemplateForm.new(permission_template)
      end

      def permission_template
        @permission_template ||= @permission_template_access.permission_template
      end
    end
  end
end

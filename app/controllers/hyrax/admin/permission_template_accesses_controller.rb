# frozen_string_literal: true
module Hyrax
  module Admin
    class PermissionTemplateAccessesController < ApplicationController
      load_and_authorize_resource class: 'Hyrax::PermissionTemplateAccess'

      def destroy
        authorize! :destroy, @permission_template_access
        ActiveRecord::Base.transaction do
          @permission_template_access.destroy
          remove_access!
        end
        if @permission_template_access.destroyed?
          after_destroy_success
        else
          after_destroy_error
        end
      end

      private

      def after_destroy_error
        if source.admin_set?
          @permission_template_access.errors[:base] <<
            t('hyrax.admin.admin_sets.form.permission_destroy_errors.participants')
          redirect_to hyrax.edit_admin_admin_set_path(source_id,
                                                      anchor: 'participants'),
                      alert: @permission_template_access.errors.full_messages.to_sentence
        else
          @permission_template_access.errors[:base] <<
            t('hyrax.dashboard.collections.form.permission_update_errors.sharing')
          redirect_to hyrax.edit_dashboard_collection_path(source_id,
                                                           anchor: 'sharing'),
                      alert: @permission_template_access.errors.full_messages.to_sentence
        end
      end

      def after_destroy_success
        if source.admin_set?
          redirect_to hyrax.edit_admin_admin_set_path(source_id,
                                                      anchor: 'participants'),
                      notice: translate('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices')
        else
          redirect_to hyrax.edit_dashboard_collection_path(source_id,
                                                           anchor: 'sharing'),
                      notice: translate('sharing', scope: 'hyrax.dashboard.collections.form.permission_update_notices')
        end
      end

      delegate :source_id, to: :permission_template

      ##
      # @todo can we avoid querying solr to deciede where to redirect? we
      #   otherwise don't need this data at all.
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

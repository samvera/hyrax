# frozen_string_literal: true

module Hyrax
  module Admin
    class MetadataProfilesController < ApplicationController
      include Hyrax::ThemedLayoutController
      require 'yaml'

      with_themed_layout 'dashboard'

      # A redirect carries the flash in the session cookie, which Rails caps at
      # 4KB after encryption, raising CookieOverflow once the action returns.
      WARNINGS_FLASH_BYTES = 1_500

      # GET /allinson_flex_profiles
      def index
        add_breadcrumbs
        @metadata_profiles = Hyrax::FlexibleSchema.page(params[:profile_entries_page])
      end

      def import
        uploaded_io = params[:file]
        if uploaded_io.blank?
          redirect_to admin_metadata_profiles_path, alert: 'Please select a file to upload'
          return
        end

        begin
          @flexible_schema = Hyrax::FlexibleSchema.create(profile: YAML.safe_load_file(uploaded_io.path))
          @flexible_schema.persisted? ? redirect_after_import : render_failed_import
        rescue => e
          redirect_to admin_metadata_profiles_path, flash: { error: e.message }
          nil
        end
      end

      def export
        @schema = Hyrax::FlexibleSchema.find(params[:metadata_profile_id])
        filename = "metadata-profile-v.#{@schema.version}.yml"

        profile_hash = @schema.profile.deep_dup

        profile_hash['profile']['version'] = @schema.version
        profile_hash['profile']['date_modified'] = Time.current.strftime('%Y-%m-%d')

        yaml_data = profile_hash.to_yaml(indentation: 2)
        send_data yaml_data, filename: filename, type: "application/yaml"
      end

      private

      def redirect_after_import
        flash_options = { notice: 'Flexible Metadata Profile was successfully created.' }
        flash_options[:alert] = warnings_that_fit_in_the_cookie if import_warnings.any?
        redirect_to admin_metadata_profiles_path, flash: flash_options
      end

      def render_failed_import
        flash.now[:error] = @flexible_schema.errors.messages.values.flatten
        flash.now[:alert] = import_warnings if import_warnings.any?
        index
        render :index, status: :unprocessable_entity
      end

      def import_warnings
        @flexible_schema.warnings.messages.values.flatten
      end

      def warnings_that_fit_in_the_cookie
        shown = []
        import_warnings.each do |warning|
          break if ActiveSupport::JSON.encode(shown + [warning]).bytesize > WARNINGS_FLASH_BYTES
          shown << warning
        end
        hidden_count = import_warnings.size - shown.size
        return shown if hidden_count.zero?

        shown + [t('hyrax.admin.metadata_profiles.import.more_warnings', count: hidden_count)]
      end

      def add_breadcrumbs
        add_breadcrumb t(:'hyrax.controls.home'), main_app.root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.dashboard.metadata_profiles'), hyrax.admin_metadata_profiles_path
      end
    end
  end
end

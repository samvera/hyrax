# frozen_string_literal: true

module Hyrax
  class MetadataProfilesController < ApplicationController
    include Hyrax::ThemedLayoutController
    require 'yaml'

    with_themed_layout 'dashboard'

    # GET /allinson_flex_profiles
    def index
      add_breadcrumbs
      @metadata_profiles = Hyrax::FlexibleSchema.page(params[:profile_entries_page])
    end

    # rubocop:disable Metrics/MethodLength
    def import
      uploaded_io = params[:file]
      if uploaded_io.blank?
        redirect_to metadata_profiles_path, alert: 'Please select a file to upload'
        return
      end

      begin
        @flexible_schema = Hyrax::FlexibleSchema.create(profile: YAML.safe_load_file(uploaded_io.path))

        if @flexible_schema.persisted?
          # After importing the profile, reload dynamic methods
          Hyrax::WorkShowPresenter.reload_dynamic_methods
          redirect_to metadata_profiles_path, notice: 'AllinsonFlexProfile was successfully created.'
        else
          redirect_to metadata_profiles_path, alert: @flexible_schema.errors.messages.to_s
        end
      rescue => e
        redirect_to metadata_profiles_path, alert: e.message
        nil
      end
    end
    # rubocop:enable Metrics/MethodLength

    def export
      @schema = Hyrax::FlexibleSchema.find(params[:metadata_profile_id])
      filename = "metadata-profile-v.#{@schema.version}.yml"
      yaml_data = @schema.profile.to_hash.to_yaml(indentation: 2)
      send_data yaml_data, filename: filename, type: "application/yaml"
    end

    private

    def add_breadcrumbs
      add_breadcrumb t(:'hyrax.controls.home'), main_app.root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.dashboard.metadata_profiles'), hyrax.metadata_profiles_path
    end
  end
end

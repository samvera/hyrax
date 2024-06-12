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

    def import
      uploaded_io = params[:file]
      if uploaded_io.blank?
        redirect_to metadata_profiles_path, alert: 'Please select a file to upload'
        return
      end

      begin
        @flexible_schema = Hyrax::FlexibleSchema.first_or_create do |f|
          f.profile = YAML.safe_load_file(uploaded_io.path)
        end

        redirect_to metadata_profiles_path, notice: 'AllinsonFlexProfile was successfully created.'
      rescue => e
        redirect_to metadata_profiles_path, alert: @flexible_schema.errors.messages.to_s
        return
      end
    end

    def export
      @allinson_flex_profile = AllinsonFlex::Profile.find(params[:profile_id])
      filename = "metadata-profile-v.#{@allinson_flex_profile.profile_version}.yml"
      File.open(filename, "w") { |file| file.write(@allinson_flex_profile.profile.to_hash.to_yaml(indentation: 8)) }
      send_file filename, type: "application/yaml", x_sendfile: true
    end

    private

      def add_breadcrumbs
        add_breadcrumb t(:'hyrax.controls.home'), main_app.root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.dashboard.metadata_profiles'), hyrax.metadata_profiles_path
      end
  end
end

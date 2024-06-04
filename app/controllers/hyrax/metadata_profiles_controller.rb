# frozen_string_literal: true

module Hyrax
  class MetadataProfilesController < ApplicationController
    include Hyrax::ThemedLayoutController
    require 'yaml'

    with_themed_layout 'dashboard'

    # GET /allinson_flex_profiles
    def index
      add_breadcrumbs
    end

    def import
      uploaded_io = params[:file]
      if uploaded_io.blank?
        redirect_to profiles_path, alert: 'Please select a file to upload'
        return
      end
    end

    private

      def add_breadcrumbs
        add_breadcrumb t(:'hyrax.controls.home'), main_app.root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.dashboard.metadata_profiles'), hyrax.metadata_profiles_path
      end
  end
end
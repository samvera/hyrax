module Worthwhile
  module CurationConcern
    class GenericWorksController < ApplicationController
      include Worthwhile::ThemedLayoutController
      load_and_authorize_resource class: "Worthwhile::GenericWork"
      with_themed_layout '1_column'

      # append_view_path("#{Worthwhile::Engine.config.root}/app/views/worthwhile/curation_concern/base")

      def curation_concern
        @generic_work
      end
      helper_method :curation_concern

      
      def contributor_agreement
        @contributor_agreement ||= ContributorAgreement.new(curation_concern, current_user, params)
      end

      helper_method :contributor_agreement

      def new
      end

      def create
        # @generic_work.attributes = params[:generic_work]
        # @generic_work.save
      end

      def show
      end

      def edit
      end

      def update
      end

      def destroy
      end

      def _prefixes
        @_prefixes ||= super + ['worthwhile/curation_concern/base']
      end

    end
  end
end

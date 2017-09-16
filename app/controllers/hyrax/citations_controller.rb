module Hyrax
  class CitationsController < ApplicationController
    include WorksControllerBehavior
    include Breadcrumbs
    include SingularSubresourceController

    layout :decide_layout
    before_action :build_breadcrumbs, only: [:work, :file]

    def work
      show
    end

    def file
      # We set _@presenter_ here so it isn't set in WorksControllerBehavior#presenter
      # which is intended to find works (not files)
      solr_file = ::SolrDocument.find(params[:id])
      authorize! :show, solr_file
      @presenter = FileSetPresenter.new(solr_file, current_ability, request)
      show
    end

    private

      def show_presenter
        WorkShowPresenter
      end

      def decide_layout
        case action_name
        when 'work', 'file'
          theme
        else
          # Not currently used in this controller, but left here to
          # support dashboard-based work views which are ticketed
          'dashboard'
        end
      end
  end
end

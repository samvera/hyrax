module Hyrax
  class CitationsController < ApplicationController
    include CurationConcernController
    include Breadcrumbs
    include SingularSubresourceController

    before_action :build_breadcrumbs, only: [:work, :file]

    def work
      @presenter_class = WorkShowPresenter
      show
    end

    def file
      @presenter_class = FileSetPresenter
      show
    end

    protected

      def show_presenter
        @presenter_class
      end
  end
end

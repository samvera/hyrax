class CitationsController < ApplicationController
  include CurationConcerns::CurationConcernController
  include Sufia::Breadcrumbs
  include Sufia::SingularSubresourceController

  before_action :build_breadcrumbs, only: [:work, :file]

  def work
    @presenter_class = Sufia::WorkShowPresenter
    show
  end

  def file
    @presenter_class = Sufia::FileSetPresenter
    show
  end

  protected

    def show_presenter
      @presenter_class
    end
end

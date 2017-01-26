module Hyrax
  # Shows the about page
  class PagesController < ApplicationController
    helper Hyrax::ContentBlockHelper

    layout 'homepage'

    def show
      @page = ContentBlock.find_or_create_by(name: params[:id])
    end
  end
end

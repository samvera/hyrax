module Hyrax
  class PagesController < ApplicationController
    helper Hyrax::ContentBlockHelper
    def show
      @page = ContentBlock.find_or_create_by(name: params[:id])
    end
  end
end

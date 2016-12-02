module Sufia
  class PagesController < ApplicationController
    def show
      @page = ContentBlock.find_or_create_by(name: params[:id])
    end
  end
end

class PagesController < ApplicationController
  layout 'homepage'

  def show
    @page = ContentBlock.find_or_create_by(name: params[:id])
  end
end

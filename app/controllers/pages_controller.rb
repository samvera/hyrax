class PagesController < ApplicationController

  def show
    @page = ContentBlock.find_by_name(params[:id])
    unless @page
      authorize! :create, ContentBlock
      @page = ContentBlock.create(name: params[:id])
    end
  end

end

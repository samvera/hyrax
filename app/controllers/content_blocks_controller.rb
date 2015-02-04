class ContentBlocksController < ApplicationController
  load_and_authorize_resource except: :index
  before_filter :load_featured_researchers, only: :index
  authorize_resource only: :index

  def index
  end

  def create
    @content_block.save
    redirect_to :back
  end

  def update
    @content_block.update(update_params)
    redirect_to :back
  end

protected

  def create_params
    params.require(:content_block).permit([:name, :value, :external_key])
  end

  def update_params
    params.require(:content_block).permit([:value, :external_key])
  end

  def load_featured_researchers
    @content_blocks = ContentBlock.recent_researchers.page(params[:page])
  end

end

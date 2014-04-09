class ContentBlocksController < ApplicationController
  load_and_authorize_resource

  def update
    @content_block.update(params.require(:content_block).permit(:value))
    redirect_to :back
  end
end

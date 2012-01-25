class GenericFilesController < ApplicationController

  def new
    @file_asset = GenericFile.new 
  end

  def create
    @file_asset = GenericFile.new(params[:generic_file])
    if (@generic_asset.save)
      flash[:success] = "You saved #{@generic_asset.title}"
      render :action=>"edit"
    else 
      flash[:error] = "Unable to save."
      render :action=>"new"
    end
  end

  def audit
    @file_asset = GenericFile.find(params[:id])
    render :json=>@file_asset.content.audit
    
  end
end

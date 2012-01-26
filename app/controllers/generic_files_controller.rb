class GenericFilesController < ApplicationController

  def new
    @generic_file = GenericFile.new 
  end

  def create
    @generic_file = GenericFile.new(params[:generic_file].reject {|k,v| k=="Filedata" || k=="Filename"})
    
    if (@generic_file.save)
      flash[:success] = "You saved #{@generic_file.title}"
      redirect_to :action=>"edit", :id=>@generic_file.pid
    else 
      flash[:error] = "Unable to save."
      render :action=>"new"
    end
  end
  
  def edit
    @generic_file = GenericFile.find(params[:id])
  end

  def show
    @generic_file = GenericFile.find(params[:id])
  end

  def audit
    @generic_file = GenericFile.find(params[:id])
    render :json=>@generic_file.content.audit
  end
end

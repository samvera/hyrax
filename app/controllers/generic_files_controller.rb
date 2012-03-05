class GenericFilesController < ApplicationController
  
  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  before_filter :authenticate_user!
  before_filter :enforce_access_controls, :only=>[:edit, :update]
  
  def new
    @generic_file = GenericFile.new 
  end

  def edit
    @generic_file = GenericFile.find(params[:id])
  end

  def create
    
    @generic_files = create_and_save_generic_files_from_params
    if @generic_files.empty? 
      flash[:notice] = "You must specify a file to upload" 
      redirect_params = {:controller => "generic_files", :action => "new"} 
    else
      notice = []
      @generic_files.each do |gf|
        notice << render_to_string(:partial=>'generic_files/asset_saved_flash', :locals => { :generic_file => gf })
      end
      flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
      redirect_params = {:controller => "catalog", :action => "index"} 
    end
    redirect_to redirect_params 
  end

  def show
    @generic_file = GenericFile.find(params[:id])
  end

  def audit
    @generic_file = GenericFile.find(params[:id])
    render :json=>@generic_file.content.audit
  end
 
  def update
    @generic_file = GenericFile.find(params[:id])
    @generic_file.update_attributes(params[:generic_file].reject {|k,v| k=="Filedata" || k=="Filename"})
    flash[:notice] = "Successfully updated." 
    if params.has_key?(:Filedata) 
        add_posted_blob_to_asset(generic_file,params[:Filedata])
    end 
    render :edit 
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


  protected
  # takes form file inputs and assigns meta data individually 
  # to each generic file asset and saves generic file assets # @param [Hash] of form fields
  def create_and_save_generic_files_from_params
    @generic_files = []
    puts "obj is #{@generic_files.inspect}"
    puts "passed parms #{params[:generic_file]}"
    if params.has_key?(:Filedata)
      puts "okay so there is a Filedata param"
      params[:Filedata].each do |file|
        puts "file"
        generic_file = GenericFile.new(params[:generic_file].reject {|k,v| k=="Filedata" || k=="Filename"})
        
        add_posted_blob_to_asset(generic_file,file)
        apply_depositor_metadata(generic_file)
        generic_file.label = file.original_filename
        # Delete this next line when GenericFile.label no longer wipes out the title
        generic_file.title = params[:generic_file][:title] if params[:generic_file].has_key?(:title) 
        generic_file.save
        @generic_files << generic_file
      end
    else
      puts "no key"
    end
    @generic_files
  end
end

class GenericFilesController < ApplicationController
  
  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  before_filter :authenticate_user!
  before_filter :enforce_access_controls, :only=>[:edit, :update]
  
  def new
    @generic_file = GenericFile.new 
  end

  def create
    
    @generic_files = create_and_save_generic_files_from_params
    notice = []
    @generic_files.each do |gf|
      notice << render_to_string(:partial=>'generic_files/asset_saved_flash', :locals => { :generic_file => gf })
    end
    flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
    redirect_to catalog_index_path
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
    
    if params.has_key?(:Filedata)
      @generic_files = []
      params[:Filedata].each do |file|
        generic_file = GenericFile.new(params[:generic_file].reject {|k,v| k=="Filedata" || k=="Filename"})
        
        add_posted_blob_to_asset(generic_file,file)
        generic_file.label = file.original_filename
        generic_file.save
        @generic_files << generic_file
      end
      return @generic_files
    else
      render :text => "400 Bad Request", :status => 400
    end
  end

  def process_files
    @file_assets = create_and_save_file_assets_from_params
    notice = []
    @file_assets.each do |file_asset|
      apply_depositor_metadata(file_asset)

      notice << render_to_string(:partial=>'file_assets/asset_saved_flash', :locals => { :file_asset => file_asset })
        
      if !params[:container_id].nil?
        associate_file_asset_with_container(file_asset,'info:fedora/' + params[:container_id])
      end

      ## Apply any posted file metadata
      unless params[:asset].nil?
        logger.debug("applying submitted file metadata: #{@sanitized_params.inspect}")
        apply_file_metadata
      end
      # If redirect_params has not been set, use {:action=>:index}
      logger.debug "Created #{file_asset.pid}."
    end
    notice
  end
end

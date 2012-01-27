class GenericFilesController < ApplicationController
  
  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method

  before_filter :authenticate_user!
  before_filter :enforce_access_controls, :only=>[:edit, :update]
  
  def new
    @generic_file = GenericFile.new 
  end

  def create
    @generic_file = GenericFile.new(params[:generic_file].reject {|k,v| k=="Filedata" || k=="Filename"})
    apply_depositor_metadata(@generic_file)
    
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
  
  protected
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

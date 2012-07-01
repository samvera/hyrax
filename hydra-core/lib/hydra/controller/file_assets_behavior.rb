# will move to lib/hydra/controller / file_assets_controller_behavior.rb in release 5.x
module Hydra::Controller::FileAssetsBehavior
  extend ActiveSupport::Concern
  
  included do
    include Hydra::AccessControlsEnforcement
    include Hydra::AssetsControllerHelper
    include Hydra::Controller::UploadBehavior 
    include Hydra::Controller::RepositoryControllerBehavior
    include Hydra::UI::Controller
    include Blacklight::SolrHelper
    include Hydra::SubmissionWorkflow
    include Blacklight::Configurable
    copy_blacklight_config_from(CatalogController)
    prepend_before_filter :sanitize_update_params
    helper :hydra_uploader
  end
  
  def index
    if params[:layout] == "false"
      layout = false
    end

    if params[:asset_id].nil?
      @solr_result = FileAsset.find_by_solr(:all)
    else
      container_uri = "info:fedora/#{params[:asset_id]}"
      escaped_uri = container_uri.gsub(/(:)/, '\\:')
      extra_controller_params =  {:q=>"is_part_of_s:#{escaped_uri}", :qt=>'standard'}
      @response, @document_list = get_search_results( extra_controller_params )
      
      # Including this line so permissions tests can be run against the container
      @container_response, @document = get_solr_response_for_doc_id(params[:asset_id])
      
      # Including these lines for backwards compatibility (until we can use Rails3 callbacks)
      @container =  ActiveFedora::Base.find(params[:asset_id], :cast=>true)
      @solr_result = @container.parts(:response_format=>:solr)
    end
    
    # Load permissions_solr_doc based on params[:asset_id]
    load_permissions_from_solr(params[:asset_id])
    
    render :action=>params[:action], :layout=>layout
  end
  
  def new
    render :partial=>"new", :layout=>false
  end
  
  # Creates and Saves a File Asset to contain the the Uploaded file 
  # If container_id is provided:
  # * the File Asset will use RELS-EXT to assert that it's a part of the specified container
  # * the method will redirect to the container object's edit view after saving
  def create
    if params.has_key?(:number_of_files) and params[:number_of_files] != "0"
      return redirect_to edit_catalog_path(params[:id], :wf_step => :files, :number_of_files => params[:number_of_files])
    elsif params.has_key?(:number_of_files) and params[:number_of_files] == "0"
      return redirect_to next_step(params[:id])
    end
    
    if params.has_key?(:Filedata)
      notice = process_files
      flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
    else
      flash[:notice] = "You must specify a file to upload."
    end
    
    if params[:container_id]
      redirect_to next_step(params[:container_id])
    else
      redirect_to catalog_index_path
    end

  end

  def process_files
    @file_assets = create_and_save_file_assets_from_params
    notice = []
    @file_assets.each do |file_asset|
      apply_depositor_metadata(file_asset)

      notice << render_to_string(:partial=>'hydra/file_assets/asset_saved_flash', :locals => { :file_asset => file_asset })
        
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
  
  # Common destroy method for all AssetsControllers 
  def destroy
    ActiveFedora::Base.find(params[:id], :cast=>true).delete 

    flash[:notice] = "Deleted #{params[:id]} from #{params[:container_id]}."
    
    if !params[:container_id].nil?
      redirect_params = edit_catalog_path(params[:container_id], :anchor => "file_assets")
    end
    redirect_params ||= {:action => 'index', :q => nil , :f => nil}
    
    redirect_to redirect_params
    
  end
  
  
  def show
    begin
      @file_asset = FileAsset.find(params[:id])
    rescue ActiveFedora::ObjectNotFoundError
      logger.warn("No such file asset: " + params[:id])
      flash[:notice]= "No such file asset."
      redirect_to(:action => 'index', :q => nil , :f => nil)
      return
    end
    # get containing object for this FileAsset
    pid = @file_asset.container_id
    parent = ActiveFedora::Base.find(pid, :cast=>true)
    @downloadable = false
    # A FileAsset is downloadable iff the user has read or higher access to a parent

    if can? :read, parent
      # First try to use datastream_id value (set in FileAssetsHelper)
      if @file_asset.datastreams.include?(datastream_id)
        send_datastream @file_asset.datastreams[datastream_id]
      elsif @file_asset.datastreams.include?("DS1")
        send_datastream @file_asset.datastreams["DS1"]
      end
    else
      raise Hydra::AccessDenied.new("You do not have sufficient access privileges to download this file.")
    end
  end
end


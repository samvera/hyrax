module Hydra::FileAssets
  extend ActiveSupport::Concern
  
  include Hydra::AccessControlsEnforcement
  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
  include Hydra::RepositoryController  
  include MediaShelf::ActiveFedoraHelper
  include Blacklight::SolrHelper
  
  included do
    before_filter :require_solr, :only=>[:index, :create, :show, :destroy]
    # need to include this after the :require_solr/fedora before filters because of the before filter that the workflow provides.
    include Hydra::SubmissionWorkflow
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
      extra_controller_params =  {:q=>"is_part_of_s:#{escaped_uri}"}
      @response, @document_list = get_search_results( extra_controller_params )
      
      # Including this line so permissions tests can be run against the container
      @container_response, @document = get_solr_response_for_doc_id(params[:asset_id])
      
      # Including these lines for backwards compatibility (until we can use Rails3 callbacks)
      @container =  ActiveFedora::Base.load_instance(params[:asset_id])
      @solr_result = @container.file_objects(:response_format=>:solr)
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
      return redirect_to({:controller => "catalog", :action => "edit", :id => params[:id], :wf_step => :files, :number_of_files => params[:number_of_files]})
    elsif params.has_key?(:number_of_files) and params[:number_of_files] == "0"
      return redirect_to( {:controller => "catalog", :action => "edit", :id => params[:id]}.merge(params_for_next_step_in_wokflow) )
    end
    
    if params.has_key?(:Filedata)
      notice = process_files
      flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
    else
      flash[:notice] = "You must specify a file to upload."
    end
    
    unless params[:container_id].nil?
      redirect_params = {:controller => "catalog", :action => "edit", :id => params[:container_id]}.merge(params_for_next_step_in_wokflow)
    end
    redirect_params ||= {:controller => "catalog", :action => "index"}
    
    redirect_to redirect_params
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
  
  # Common destroy method for all AssetsControllers 
  def destroy
    # The correct implementation, with garbage collection:
    # if params.has_key?(:container_id)
    #   container = ActiveFedora::Base.load_instance(params[:container_id]) 
    #   container.file_objects_remove(params[:id])
    #   FileAsset.garbage_collect(params[:id])
    # else
    
    # The dirty implementation (leaves relationship in container object, deletes regardless of whether the file object has other containers)
    ActiveFedora::Base.load_instance(params[:id]).delete 

    flash[:notice] = "Deleted #{params[:id]} from #{params[:container_id]}."
    
    if !params[:container_id].nil?
      redirect_params = {:controller => "catalog", :action => "edit", :id => params[:container_id], :anchor => "file_assets"}
    end
    redirect_params ||= {:action => 'index', :q => nil , :f => nil}
    
    redirect_to redirect_params
    
  end
  
  
  def show
    @file_asset = FileAsset.find(params[:id])
    if (@file_asset.nil?)
      logger.warn("No such file asset: " + params[:id])
      flash[:notice]= "No such file asset."
      redirect_to(:action => 'index', :q => nil , :f => nil)
    else
      # get array of parent (container) objects for this FileAsset
      @id_array = @file_asset.containers(:response_format => :id_array)
      @downloadable = false
      # A FileAsset is downloadable iff the user has read or higher access to a parent
      @id_array.each do |pid|
        @response, @permissions_solr_document = get_solr_response_for_doc_id(pid)
        if reader?
          @downloadable = true
          break
        end
      end

      if @downloadable
        if @file_asset.datastreams.include?("DS1")
          send_datastream @file_asset.datastreams["DS1"]
        end
      else
        flash[:notice]= "You do not have sufficient access privileges to download this document, which has been marked private."
        redirect_to(:action => 'index', :q => nil , :f => nil)
      end
    end
  end
end


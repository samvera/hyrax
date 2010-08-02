class FileAssetsController < ApplicationController
  
  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
  include Hydra::RepositoryController  
  include MediaShelf::ActiveFedoraHelper
  include Blacklight::SolrHelper
  
  before_filter :require_fedora
  before_filter :require_solr, :only=>[:index, :create, :show, :destroy]
  
  
  def index
    if params[:layout] == "false"
      # action = "index_embedded"
      layout = false
    end
    if !params[:container_id].nil?
      @response, @document = get_solr_response_for_doc_id(params[:container_id])
      @container =  ActiveFedora::Base.load_instance(params[:container_id])
      @solr_result = @container.collection_members(:response_format=>:solr)
    else
      # @solr_result = ActiveFedora::SolrService.instance.conn.query('has_model_field:info\:fedora/afmodel\:FileAsset', @search_params)
      @solr_result = FileAsset.find_by_solr(:all)
    end
    render :action=>params[:action], :layout=>layout
  end
  
  def new
    render :partial=>"new", :layout=>false
  end
  
  def create
    @file_asset = create_and_save_file_asset_from_params
    apply_depositor_metadata(@file_asset)
    
    if !params[:container_id].nil?
      @container =  ActiveFedora::Base.load_instance(params[:container_id])
      @container.file_objects_append(@file_asset)
      @container.save
    end
    render :nothing => true
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
    render :text => "Deleted #{params[:id]} from #{params[:container_id]}."
  end
  
  
  def show
    @file_asset = FileAsset.find(params[:id]) #.hits.first
    if @file_asset.datastreams_in_memory.include?("DS1")
      send_datastream @file_asset.datastreams_in_memory["DS1"]
    end
    # @solr_result = FileAsset.find_by_solr(params[:id]).hits.first
    # if params[:layout] == "false"
    #   render :action=>"show_embedded", :layout=>false
    # end
    # add_crumb @file_asset.pid, @file_asset
  end
end

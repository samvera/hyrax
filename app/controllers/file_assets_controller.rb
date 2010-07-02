class FileAssetsController < ApplicationController
  
  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
  include Hydra::RepositoryController  
  include MediaShelf::ActiveFedoraHelper
  include Blacklight::SolrHelper
  
  before_filter :require_fedora
  before_filter :require_solr, :only=>[:index, :create, :show]
  
  
  def index
    if params[:layout] == "false"
      action = "index_embedded"
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
    render :action=>action, :layout=>layout
  end
  
  def new
    render :partial=>"new", :layout=>false
  end
  
  def create
    
    create_and_save_file_asset_from_params
    
    if !params[:container_id].nil?
      @container =  ActiveFedora::Base.load_instance(params[:container_id])
      @container.file_objects_append(@file_asset)
      @container.save
    end
    render :nothing => true
  end
  
  def show
    @file_asset = FileAsset.find(params[:id]) #.hits.first
    @solr_result = FileAsset.find_by_solr(params[:id]).hits.first
    if params[:layout] == "false"
      render :action=>"show_embedded", :layout=>false
    end
    # add_crumb @file_asset.pid, @file_asset
  end
end

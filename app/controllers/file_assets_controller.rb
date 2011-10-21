class FileAssetsController < ApplicationController
  
  include Hydra::AccessControlsEnforcement
  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
  include Hydra::RepositoryController  
  include MediaShelf::ActiveFedoraHelper
  include Blacklight::SolrHelper
  
  before_filter :require_solr, :only=>[:index, :create, :show, :destroy]

  # need to include this after the :require_solr/fedora before filters because of the before filter that the workflow provides.
  include Hydra::SubmissionWorkflow

  prepend_before_filter :sanitize_update_params
  
  helper :hydra_uploader
  
  def index
=begin
Removed from file_assets/index.html.haml
-# javascript_includes << infusion_javascripts(:inline_edit, :extras=>[:inline_editor_integrations], :debug=>true, :render_html=>false) 
-# javascript_includes << ['../infusion/framework/core/js/ProgressiveEnhancement.js', '../infusion/InfusionAll.js', {:cache=>true, :plugin=>"fluid-infusion"}]

- javascript_includes << "jquery.jeditable.mini"
- javascript_includes << 'custom'
- javascript_includes << "catalog/edit"
- javascript_includes << "jquery.hydraMetadata.js"  
- javascript_includes << "/plugin_assets/fluid-infusion/infusion/components/undo/js/Undo.js" 
- javascript_includes << "jquery.form.js"




=end

    if params[:layout] == "false"
      # action = "index_embedded"
      layout = false
    end

    if params[:asset_id].nil?
      # @solr_result = ActiveFedora::SolrService.instance.conn.query('has_model_field:info\:fedora/afmodel\:FileAsset', @search_params)
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
=begin
From file_assets/_new.html.haml
=render :partial=>"fluid_infusion/uploader"
=render :partial=>"fluid_infusion/uploader_js"
=end
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
      @file_assets = create_and_save_file_assets_from_params
      notice = []
      @file_assets.each do |file_asset|
        apply_depositor_metadata(file_asset)

        notice << "The file #{file_asset.label} has been saved in <a href=\"#{asset_url(file_asset.pid)}\">#{file_asset.pid}</a>."
          
#### TODO - jcoyne I think this is not working
#debugger
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
      flash[:notice] = notice.join("<br/>") unless notice.blank?
    else
      flash[:notice] = "You must specify a file to upload."
    end
    
    unless params[:container_id].nil?
      redirect_params = {:controller => "catalog", :action => "edit", :id => params[:container_id]}.merge(params_for_next_step_in_wokflow)
    end
    redirect_params ||= {:controller => "catalog", :action => "index"}
    
    redirect_to redirect_params
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
        if @file_asset.datastreams_in_memory.include?("DS1")
          send_datastream @file_asset.datastreams_in_memory["DS1"]
        end
      else
        flash[:notice]= "You do not have sufficient access privileges to download this document, which has been marked private."
        redirect_to(:action => 'index', :q => nil , :f => nil)
      end
    end
  end
  
end

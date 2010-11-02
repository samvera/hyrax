require 'mediashelf/active_fedora_helper'
class CatalogController
  
  #include Blacklight::CatalogHelper
  include Hydra::RepositoryController
  include Hydra::AccessControlsEnforcement
  before_filter :require_solr, :require_fedora, :only=>[:show, :edit, :index]
  
  def edit
    af_base = ActiveFedora::Base.load_instance(params[:id])
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    if the_model.nil?
      the_model = DcDocument
    end
    @document_fedora = the_model.load_instance(params[:id])
    #fedora_object = ActiveFedora::Base.load_instance(params[:id])
    #params[:action] = "edit"
    #@downloadables = downloadables( @document_fedora )
    show_without_customizations
    enforce_edit_permissions
  end
  
  # get search results from the solr index
  def index
    @extra_controller_params ||= {}
    # The query lucene query builder should take care of the perms now.
    #if current_user.nil?
    #  enforce_search_permissions
    #end

    (@response, @document_list) = get_search_results( @extra_controller_params.merge!(:q=>build_lucene_query(params[:q])) )
    @filters = params[:f] || []
    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
    end
    rescue RSolr::RequestError
      logger.error("Unparseable search error: #{params.inspect}" ) 
      flash[:notice] = "Sorry, I don't understand your search." 
      redirect_to :action => 'index', :q => nil , :f => nil
    rescue 
      logger.error("Unknown error: #{params.inspect}" ) 
      flash[:notice] = "Sorry, you've encountered an error. Try a different search." 
      redirect_to :action => 'index', :q => nil , :f => nil
  end
    
  def show_with_customizations
    show_without_customizations
    enforce_viewing_context_for_show_requests
    af_base = ActiveFedora::Base.load_instance(params[:id])
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    if the_model.nil?
      the_model = DcDocument
    end
    @document_fedora = the_model.load_instance(params[:id])
    params = {:qt=>"dismax",:q=>"*:*",:rows=>"0",:facet=>"true", :facets=>{:fields=>Blacklight.config[:facet][:field_names]}}
    @facet_lookup = Blacklight.solr.find params
    enforce_read_permissions
  end
  
  # trigger show_with_customizations when show is called
  # This has the same effect as the (deprecated) alias_method_chain :show, :find_folder_siblings
  alias_method :show_without_customizations, :show
  alias_method :show, :show_with_customizations


  # 
  ### This was how get_search_results in SALT deals with switching solr instances
  #
  # def get_search_results(extra_controller_params={})
  #   _search_params = self.solr_search_params(extra_controller_params)
  #   index = _search_params[:qt] == 'fulltext' ? :fulltext : :default
  #   
  #   document_list = solr_response.docs.collect {|doc| SolrDocument.new(doc)}
  #   
  #   Blacklight.solr(index).find(_search_params)
  #   
  #   return [solr_response, document_list]
  #   
  # end
  protected
  
  # a solr query method
  # this is used when selecting a search result: we have a query and a 
  # position in the search results and possibly some facets
  def get_single_doc_via_search(extra_controller_params={})
    solr_params = solr_search_params(extra_controller_params)
    solr_params[:per_page] = 1
    solr_params[:fl] = '*'
    if params[:q].to_s.blank?
      solr_params.merge!(:q=>build_lucene_query(params[:q]))
    end
    Blacklight.solr.find(solr_params).docs.first
  end

  # This method will remove certain params from the session[:search] hash
  # if the values are blank? (nil or empty string)
  # if the values aren't blank, they are saved to the session in the :search hash.
  # We're overriding this for SALT because we need to add in the view parameter to 
  # make sure that the user is taken back to the same view (gallery/list) that they came from
  def delete_or_assign_search_session_params
    [:q, :qt, :search_field, :f, :per_page, :page, :sort, :view].each do |pname|
      params[pname].blank? ? session[:search].delete(pname) : session[:search][pname] = params[pname]
    end
  end

end

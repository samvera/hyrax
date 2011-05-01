require_plugin_dependency File.join('vendor','plugins','blacklight','app','controllers','catalog_controller.rb')
require 'mediashelf/active_fedora_helper'
class CatalogController
  
  include Blacklight::CatalogHelper
  include Hydra::RepositoryController
  include Hydra::AccessControlsEnforcement
  include Hydra::FileAssetsHelper  
  
  before_filter :require_solr, :require_fedora, :only=>[:show, :edit, :index, :delete]
    
  def edit
    
=begin
HYDRA-150

This was pulled from _edit_partials/default.html.erb:
<%- javascript_includes << infusion_javascripts(:inline_edit, :extras=>[:inline_editor_integrations], :debug=>true, :render_html=>false) %>
<%  javascript_includes << ["jquery.jeditable.mini.js", "date-picker/js/datepicker", "jquery.form.js", 'custom', "catalog/edit", "jquery.hydraMetadata.js", "fancybox/jquery.fancybox-1.3.1.pack.js", "select_to_ui_slider/selectToUISlider.jQuery.js", {:plugin=>"hydra-head"}] %>

Pulled from _edit_partials/_default_details.html.erb
<%- javascript_includes << "/plugin_assets/fluid-infusion/infusion/components/undo/js/Undo.js" %>
<%- javascript_includes << ["jquery.notice.js", {:plugin=>"hydra-head"}] %>

Pulled from generic_contents/_edit.html.erb
<% javascript_includes << infusion_javascripts(:default_no_jquery, :extras=>[:inline_editor_integrations], :debug=>true, :render_html=>false) %>
<% javascript_includes << ["jquery.jeditable.mini.js", "date-picker/js/datepicker", "jquery.form.js", 'custom', "catalog/edit", "jquery.hydraMetadata.js", "jquery.notice.js", {:plugin=>"hydra-head"}] %>
<% javascript_includes << "/plugin_assets/fluid-infusion/infusion/components/undo/js/Undo.js" %>
<%# For Fancybox> %>
<% javascript_includes << ["fancybox/jquery.fancybox-1.3.1.pack.js", {:plugin=>"hydra-head"}] %>
<% javascript_includes << ["select_to_ui_slider/selectToUISlider.jQuery.js", {:plugin=>"hydra-head"}] %>
<%#= render :partial => "permissions/index", :locals => {:document => document, :asset_id=>params[:id]} %>

Pulled generic_images/_edit.html.erb
<% javascript_includes << infusion_javascripts(:default_no_jquery, :extras=>[:inline_editor_integrations], :debug=>true, :render_html=>false) %>
<% javascript_includes << ["jquery.jeditable.mini.js", "date-picker/js/datepicker", "jquery.form.js", 'custom', "catalog/edit", "jquery.hydraMetadata.js", "jquery.notice.js", {:plugin=>"hydra-head"}] %>
<% javascript_includes << "/plugin_assets/fluid-infusion/infusion/components/undo/js/Undo.js" %>
<%# For Fancybox> %>
<% javascript_includes << ["fancybox/jquery.fancybox-1.3.1.pack.js", {:plugin=>"hydra-head"}] %>
<% javascript_includes << ["select_to_ui_slider/selectToUISlider.jQuery.js", {:plugin=>"hydra-head"}] %>
<%# render :partial=>"fluid_infusion/uploader_generic_content_objects.js" %>

Pulled from vendor/plugins/hydrangea_datasets/app/views/_edit.html
<% javascript_includes << infusion_javascripts(:default_no_jquery, :extras=>[:inline_editor_integrations], :debug=>true, :render_html=>false) %>
<% javascript_includes << ["jquery.jeditable.mini.js", "date-picker/js/datepicker", "jquery.form.js", 'custom', "catalog/edit", "jquery.hydraMetadata.js", "jquery.notice.js", {:plugin=>"hydra-head"}] %>
<%- # Isn't this loaded above in the unfustion_javascripts helper? -%>
<% javascript_includes << ["../infusion/components/undo/js/Undo.js", {:plugin=>:"fluid-infusion", :media=>"all"}] %>
<%# For DatePicker> %>
<%- javascript_includes << ["jquery.ui.widget.js","jquery.ui.datepicker.js", "mediashelf.datepicker.js", {:plugin=>"hydra-head" }] %>
<%# For Fancybox> %>
<% javascript_includes << ["fancybox/jquery.fancybox-1.3.1.pack.js", {:plugin=>"hydra-head"}] %>
<% javascript_includes << ["select_to_ui_slider/selectToUISlider.jQuery.js", {:plugin=>"hydra-head"}] %>

Pulled from vendor/plugins/hydrangea_articles/app/views/_edit.html.erb
<% javascript_includes << infusion_javascripts(:default_no_jquery, :extras=>[:inline_editor_integrations], :debug=>true, :render_html=>false) %>
<% javascript_includes << ["jquery.jeditable.mini.js", {:plugin=>"hydra-head", :media=>"all"}] %>
<%# javascript_includes << "date-picker/js/datepicker" %>
<% javascript_includes << ["jquery.form.js", {:plugin=>"hydra-head", :media=>"all"}] %>
<% javascript_includes << ['custom', {:plugin=>"hydra-head", :media=>"all"}] %>
<% javascript_includes << ["catalog/edit", {:plugin=>"hydra-head", :media=>"all"}] %>
<% javascript_includes << ["jquery.hydraMetadata.js", {:plugin=>"hydra-head", :media=>"all"}] %>
<% javascript_includes << ["jquery.notice.js", {:plugin=>"hydra-head", :media=>"all"}] %>
<% javascript_includes << ["jquery.jeditable.mini.js", "date-picker/js/datepicker", "jquery.form.js", 'custom', "catalog/edit", "jquery.hydraMetadata.js", "jquery.notice.js", {:plugin=>"hydra-head"}] %>
<%- # Isn't this loaded above in the unfustion_javascripts helper? -%>
<% javascript_includes << ["../infusion/components/undo/js/Undo.js", {:plugin=>:"fluid-infusion", :media=>"all"}] %>
<%# For DatePicker> %>
<%- javascript_includes << ["jquery.ui.widget.js","jquery.ui.datepicker.js", "mediashelf.datepicker.js", {:plugin=>"hydra-head" }] %>
<%# For Fancybox> %>
<% javascript_includes << ["fancybox/jquery.fancybox-1.3.1.pack.js", {:plugin=>"hydra-head"}] %>
<%# For slider controls %>
<% javascript_includes << ["select_to_ui_slider/selectToUISlider.jQuery.js", {:plugin=>"hydra-head"}] %>

Pulled from vendor/plugins/hydrangea_articles/app/views/_edit_description.html.erb
<%- javascript_includes << ["jquery.hydraProgressBox.js", {:plugin=>"hydra-head", :media=>"all"}] %>

Pulled from vendor/plugins/hydrangea_articles/app/views/_progress_box.html.erb
<%- javascript_includes << "jquery.hydraProgressBox.js" %>

Pulled from vendor/plugins/admin_policy_objects/app/views/admin_policy_objects/_edit.html.erb
<% javascript_includes << infusion_javascripts(:default_no_jquery, :extras=>[:inline_editor_integrations], :debug=>true, :render_html=>false) %>
<% javascript_includes << ["jquery.jeditable.mini.js", "date-picker/js/datepicker", "jquery.form.js", 'custom', "catalog/edit", "jquery.hydraMetadata.js", "jquery.notice.js", {:plugin=>"hydra-head"}] %>
<% javascript_includes << "/plugin_assets/fluid-infusion/infusion/components/undo/js/Undo.js" %>
<%# For DatePicker> %>
<%- javascript_includes << ["jquery.ui.widget.js","jquery.ui.datepicker.js", "mediashelf.datepicker.js", {:plugin=>"hydra-head" }] %>
<%# For Fancybox> %>
<% javascript_includes << ["fancybox/jquery.fancybox-1.3.1.pack.js", {:plugin=>"hydra-head"}] %>
<% javascript_includes << ["select_to_ui_slider/selectToUISlider.jQuery.js", {:plugin=>"hydra-head"}] %>

Pulled from vendor/plugins/dor_objects/app/views/dor_object/_edit.html.erb
<% javascript_includes << infusion_javascripts(:default_no_jquery, :extras=>[:inline_editor_integrations], :debug=>true, :render_html=>false) %>
<% javascript_includes << ["jquery.jeditable.mini.js", "date-picker/js/datepicker", "jquery.form.js", 'custom', "catalog/edit", "jquery.hydraMetadata.js", "jquery.notice.js", {:plugin=>"hydra-head"}] %>
<% javascript_includes << "/plugin_assets/fluid-infusion/infusion/components/undo/js/Undo.js" %>
<%# For Fancybox> %>
<% javascript_includes << ["fancybox/jquery.fancybox-1.3.1.pack.js", {:plugin=>"hydra-head"}] %>
<% javascript_includes << ["select_to_ui_slider/selectToUISlider.jQuery.js", {:plugin=>"hydra-head"}] %>
	<%# render :partial=>"fluid_infusion/uploader_generic_content_objects.js" %>




=end
    
    
    
    af_base = ActiveFedora::Base.load_instance(params[:id])
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    if the_model.nil?
      the_model = DcDocument
    end
    
    @document_fedora = the_model.load_instance(params[:id])
    @file_assets = @document_fedora.file_objects(:response_format=>:solr)
    
    show_without_customizations
    enforce_edit_permissions
  end

  def delete
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
  
# displays values and pagination links for a single facet field
  def facet
    # adding the following for facet_pagination with Lucene queries to avoide NPE
    params[:qt] = "dismax"
    @pagination = get_facet_pagination(params[:id], params)
  end
  
  # get search results from the solr index
  def index
    @extra_controller_params ||= {}
    # The query lucene query builder should take care of the perms now.
    #if current_user.nil?
    #  enforce_search_permissions
    #end
    (@response, @document_list) = get_search_results( @extra_controller_params.merge!(:q=>build_lucene_query(params[:q])) )
    logger.debug("LUCENE QUERY: #{build_lucene_query(params[:q])}")
    logger.debug("FOUND: #{@document_list.length}")
    logger.debug("RESPONSE: #{@response.inspect}")
    logger.debug("DOCUMENT: #{@document_list.inspect}")
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
    
=begin
HYDRA-150
Pulled from generic_contents/_show.html.erb

<% javascript_includes << "/plugin_assets/fluid-infusion/infusion-1.2-src/lib/jquery/ui/js/jquery.ui.accordion.js" %>
<% javascript_includes << ['custom', "catalog/show", "fancybox/jquery.fancybox-1.3.1.pack.js", "generic_content_objects_fancybox.js", {:plugin=>"hydra-head"}] %>

Pulled from generic_images/_show.html.erb
<% javascript_includes << "/plugin_assets/fluid-infusion/infusion-1.2-src/lib/jquery/ui/js/jquery.ui.accordion.js" %>
<% javascript_includes << ['custom', "catalog/show", "fancybox/jquery.fancybox-1.3.1.pack.js", "generic_content_objects_fancybox.js", {:plugin=>"hydra-head"}] %>

Pulled from plugins/hydrangea_datasets/app/views/hydrangea_datasets/_show.html.erb
<% javascript_includes << "/plugin_assets/fluid-infusion/infusion-1.2-src/lib/jquery/ui/js/jquery.ui.accordion.js" %>
<% javascript_includes << ['custom', 'catalog/show', {:plugin=>"hydra-head"}] %>

Pulled from plugins/hydrangea_articles/app/views/hydrangea_articles/_show.html.erb
<% javascript_includes << ['custom', {:plugin=>"hydra-head", :media=>"all"}] %>
<% javascript_includes << ["catalog/show", {:plugin=>"hydra-head", :media=>"all"}] %>

Pulled from vendor/plugins/admin_policy_objects/app/views/admin_policy_objects/_show.html.erb
<% javascript_includes << "/plugin_assets/fluid-infusion/infusion-1.2-src/lib/jquery/ui/js/jquery.ui.accordion.js" %>
<% javascript_includes << ['custom', 'catalog/show', {:plugin=>"hydra-head"}] %>

Pulled from vendor/plugins/dor_objects/app/views/dor_objects/_show.html.erb
<% javascript_includes << "/plugin_assets/fluid-infusion/infusion-1.2-src/lib/jquery/ui/js/jquery.ui.accordion.js" %>
<% javascript_includes << ['custom', "catalog/show", "fancybox/jquery.fancybox-1.3.1.pack.js", "generic_content_objects_fancybox.js", {:plugin=>"hydra-head"}] %>

=end


    show_without_customizations
    enforce_viewing_context_for_show_requests
    af_base = ActiveFedora::Base.load_instance(params[:id])
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    if the_model.nil?
      the_model = DcDocument
    end
    @document_fedora = the_model.load_instance(params[:id])
    params = {:qt=>"search",:defType=>"dismax",:q=>"*:*",:rows=>"0",:facet=>"true", :facets=>{:fields=>Blacklight.config[:facet][:field_names]}}
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
  
  def setup_next_document
    @next_document = (session[:search][:counter] && session[:search][:counter].to_i > 1) ? setup_document_by_counter(session[:search][:counter].to_i + 1) : nil
  end

end

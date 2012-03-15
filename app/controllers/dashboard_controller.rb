# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
class DashboardController < ApplicationController
  include Blacklight::Controller  
  include Blacklight::Catalog
  include Hydra::Catalog

  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper
  before_filter :enforce_access_controls
  before_filter :enforce_viewing_context_for_show_requests, :only=>:show
  # This applies appropriate access controls to all solr queries
  DashboardController.solr_search_params_logic << :add_access_controls_to_solr_params
  # This filters out objects that you want to exclude from search results, like FileAssets
  DashboardController.solr_search_params_logic << :exclude_unwanted_models

  before_filter :authenticate_user!
  before_filter :enforce_access_controls, :only=>[:edit, :update]
  
  def index

    #puts facets_display_heading
    #puts facet_field_names.inspect
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => "RSS for results")
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => "Atom for results")
  
    (@response, @document_list) = get_search_results
    pp @response
    puts "------------DONE WITH @RESPONSE-----"
    #pp @document_list
    puts "-----"
    @filters = params[:f] || []
    pp @filters 
    puts "--DONE WITH FILTERS---"

    #respond_to do |format|
    #  format.html { save_current_search_params }
    #  format.rss  { render :layout => false }
    #  format.atom { render :layout => false }
    #end 

  end

end

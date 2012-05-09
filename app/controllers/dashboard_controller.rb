# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
class DashboardController < ApplicationController

  include Blacklight::Catalog
  include Hydra::Catalog
  
  before_filter :enforce_access_controls
  before_filter :enforce_viewing_context_for_show_requests, :only=>:show
  # This applies appropriate access controls to all solr queries (the internal method of this is overidden bellow to only include edit files)
  DashboardController.solr_search_params_logic << :add_access_controls_to_solr_params
  # This filters out objects that you want to exclude from search results, like FileAssets
  DashboardController.solr_search_params_logic << :exclude_unwanted_models

  before_filter :authenticate_user!
  before_filter :enforce_access_controls #, :only=>[:edit, :update]
  
  def index

    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => "RSS for results")
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => "Atom for results")
    (@response, @document_list) = get_search_results

    @filters = params[:f] || []

    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end 

  end
  
    
  protected
  
  # override the normal gated to just include edit
  #
  # Contrller before filter that sets up access-controlled lucene query in order to provide gated discovery behavior
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def apply_gated_discovery(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    # Grant access to public content
    permission_types = ["edit"]
    user_access_filters = []
    
    permission_types.each do |type|
      user_access_filters << "#{type}_access_group_t:public"
    end
    
    # Grant access based on user id & role
    unless current_user.nil?
      # for roles
      ::RoleMapper.roles(user_key).each_with_index do |role, i|
        permission_types.each do |type|
          user_access_filters << "#{type}_access_group_t:#{role}"
        end
      end
      # for individual person access
      permission_types.each do |type|
        user_access_filters << "#{type}_access_person_t:#{user_key}"        
      end
      if current_user.is_being_superuser?(session)
        permission_types.each do |type|
          user_access_filters << "#{type}_access_person_t:[* TO *]"        
        end
      end
      
      # Enforcing Embargo at Query time has been disabled.  
      # If you want to do this, set up your own solr_search_params before_filter that injects the appropriate :fq constraints for a field that expresses your objects' embargo status.
      #
      # include docs in results if the embargo date is NOT in the future OR if the current user is depositor
      # embargo_query = "(NOT embargo_release_date_dt:[NOW TO *]) OR depositor_t:#{user_key}"
      # embargo_query = "(NOT embargo_release_date_dt:[NOW TO *]) OR (embargo_release_date_dt:[NOW TO *] AND  depositor_t:#{user_key}) AND NOT (NOT depositor_t:#{user_key} AND embargo_release_date_dt:[NOW TO *])"
      # solr_parameters[:fq] << embargo_query         
    end
    solr_parameters[:fq] << user_access_filters.join(" OR ")
    logger.debug("Solr parameters: #{ solr_parameters.inspect }")
  end
end

# -*- coding: utf-8 -*-
# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'blacklight/catalog'

module Sufia
  module DashboardControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::BatchEditBehavior
    include Blacklight::Catalog

    included do
      include Hydra::BatchEditBehavior
      include Blacklight::Catalog
      include Blacklight::Configurable # comply with BL 3.7
      include ActionView::Helpers::DateHelper
      # This is needed as of BL 3.7
      self.copy_blacklight_config_from(CatalogController)

      include BlacklightAdvancedSearch::ParseBasicQ
      include BlacklightAdvancedSearch::Controller
    
    
      before_filter :authenticate_user!
      before_filter :enforce_show_permissions, :only=>:show
      before_filter :enforce_viewing_context_for_show_requests, :only=>:show
    
      # This applies appropriate access controls to all solr queries (the internal method of this is overidden bellow to only include edit files)
      self.solr_search_params_logic += [:add_access_controls_to_solr_params]
      # This filters out objects that you want to exclude from search results, like FileAssets
      self.solr_search_params_logic += [:exclude_unwanted_models]

    end

    def index
      if params[:controller] == "dashboard"
        extra_head_content << view_context.auto_discovery_link_tag(:rss, sufia.url_for(params.merge(:format => 'rss')), :title => "RSS for results")
        extra_head_content << view_context.auto_discovery_link_tag(:atom, sufia.url_for(params.merge(:format => 'atom')), :title => "Atom for results")
      else
        # This is for controllers that use this behavior that are defined outside Sufia
        extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => "RSS for results")
        extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => "Atom for results")
      end
      (@response, @document_list) = get_search_results
      @user = current_user
      @events = @user.events(100)
      @last_event_timestamp = @user.events.first[:timestamp].to_i || 0 rescue 0
      @filters = params[:f] || []
  
      # adding a key to the session so that the history will be saved so that batch_edits select all will work
      search_session[:dashboard] = true 
      respond_to do |format|
        format.html { save_current_search_params }
        format.rss  { render :layout => false }
        format.atom { render :layout => false }
      end
  
      # set up some parameters for allowing the batch controls to show appropiately
      @max_batch_size = 80
      count_on_page = @document_list.count {|doc| batch.index(doc.id)}
      @disable_select_all = @document_list.count > @max_batch_size
      batch_size = batch.uniq.size
      @result_set_size = @response.response["numFound"]
      @empty_batch = batch.empty?
      @all_checked = (count_on_page == @document_list.count)
      @entire_result_set_selected = @response.response["numFound"] == batch_size
      @batch_size_on_other_page = batch_size - count_on_page
      @batch_part_on_other_page = (@batch_size_on_other_page) > 0    
    end
      
    def activity
      # reverse events since we're prepending rows. without reverse, old events wind up first
      events = current_user.events.reverse
      # filter events to include only those that have occurred since params[:since]
      events.select! { |event| event[:timestamp].to_i > params[:since].to_i } if params[:since]
      # return the event, a formatted date string, and a numerical timestamp
      render :json => events.map { |event| [event[:action], "#{time_ago_in_words(Time.at(event[:timestamp].to_i))} ago", event[:timestamp].to_i] }
    rescue
      render :json => [] 
    end
  
    protected
    # show only files with edit permissions in lib/hydra/access_controls_enforcement.rb apply_gated_discovery
    def discovery_permissions
      ["edit"]
    end
  end
end

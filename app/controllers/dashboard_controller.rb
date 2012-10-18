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
class DashboardController < ApplicationController
  include Hydra::BatchEditBehavior
  include Blacklight::Catalog
  include Blacklight::Configurable # comply with BL 3.7
  include Hydra::Controller::ControllerBehavior
  include ActionView::Helpers::DateHelper

  # This is needed as of BL 3.7
  self.copy_blacklight_config_from(CatalogController)

  before_filter :authenticate_user!
  before_filter :enforce_access_controls
  before_filter :enforce_viewing_context_for_show_requests, :only=>:show

  # This applies appropriate access controls to all solr queries (the internal method of this is overidden bellow to only include edit files)
  DashboardController.solr_search_params_logic << :add_access_controls_to_solr_params
  # This filters out objects that you want to exclude from search results, like FileAssets
  DashboardController.solr_search_params_logic << :exclude_unwanted_models

  def index
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => "RSS for results")
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => "Atom for results")
    (@response, @document_list) = get_search_results
    @user = current_user
    @events = @user.events(100)
    @last_event_timestamp = @user.events.first[:timestamp].to_i || 0 rescue 0
    @filters = params[:f] || []

    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end
    @batch_size = batch.size
    @empty_batch = batch.empty?
    count_on_page = @document_list.count {|doc| batch.index(doc.id)}
    @all_checked = (@batch_size >= @document_list.count) && (count_on_page == @document_list.count)
    @batch_part_on_other_page = (@batch_size - count_on_page) > 0
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

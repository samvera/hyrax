require 'blacklight/catalog'

module Sufia
  module DashboardControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::BatchEditBehavior
    include Blacklight::Catalog

    include Hydra::Collections::SelectsCollections
  
    included do
      include Blacklight::Configurable
      include ActionView::Helpers::DateHelper

      self.copy_blacklight_config_from(CatalogController)

      include BlacklightAdvancedSearch::ParseBasicQ
      include BlacklightAdvancedSearch::Controller

      before_filter :authenticate_user!
      before_filter :enforce_show_permissions, only: :show
      before_filter :enforce_viewing_context_for_show_requests, only: :show

      # not filtering further with a specific access level since the catalog controller already gets the colections with edit access
      #  if we include other access levels in this controller we will need to modify this.
      before_filter :find_collections, only: :index

      # This applies appropriate access controls to all solr queries (the internal method of this is overidden bellow to only include edit files)
      self.solr_search_params_logic += [:add_access_controls_to_solr_params]

      layout 'sufia-dashboard'
    end

    def index
      (@response, @document_list) = get_search_results
      @user = current_user
      @events = @user.events(100)
      @last_event_timestamp = @user.events.first[:timestamp].to_i || 0 rescue 0
      @filters = params[:f] || []

      respond_to do |format|
        format.html { }
        format.rss  { render layout: false }
        format.atom { render layout: false }
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

    # TODO: This can be removed after we upgrade to hydra-collections 2.0.1 or greater
    def add_collection_filter(solr_parameters, user_parameters)
      super(solr_parameters, user_parameters)
      solr_parameters[:rows] = 100
    end



    def search_action_url *args
      sufia.dashboard_index_path *args
    end

    protected
    # show only files with edit permissions in lib/hydra/access_controls_enforcement.rb apply_gated_discovery
    def discovery_permissions
      ["edit"]
    end

    def show_only_files_deposited_by_current_user(solr_parameters, user_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += [
        ActiveFedora::SolrService.construct_query_for_rel(depositor: current_user.user_key)
      ]
    end

    def show_only_generic_files(solr_parameters, user_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += [
        ActiveFedora::SolrService.construct_query_for_rel(has_model: ::GenericFile.to_class_uri)
      ]
    end

  end
end

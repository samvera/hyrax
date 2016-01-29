module Sufia
  module MyControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Catalog
    include Hydra::BatchEditBehavior
    include Hydra::Collections::SelectsCollections

    included do
      include Blacklight::Configurable

      copy_blacklight_config_from(CatalogController)
      blacklight_config.search_builder_class = Sufia::MySearchBuilder

      before_action :authenticate_user!
      before_action :enforce_show_permissions, only: :show
      before_action :enforce_viewing_context_for_show_requests, only: :show
      before_action :find_collections, only: :index
      before_action :find_collections_with_edit_access, only: :index

      self.search_params_logic += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr]

      layout 'sufia-dashboard'
    end

    def index
      @user = current_user
      (@response, @document_list) = query_solr
      @events = @user.events(100)
      @last_event_timestamp = begin
                                @user.events.first[:timestamp].to_i || 0
                              rescue
                                0
                              end
      @filters = params[:f] || []

      # set up some parameters for allowing the batch controls to show appropriately
      @max_batch_size = 80
      count_on_page = @document_list.count { |doc| batch.index(doc.id) }
      @disable_select_all = @document_list.count > @max_batch_size
      batch_size = batch.uniq.size
      @result_set_size = @response.response["numFound"]
      @empty_batch = batch.empty?
      @all_checked = (count_on_page == @document_list.count)
      @entire_result_set_selected = @response.response["numFound"] == batch_size
      @batch_size_on_other_page = batch_size - count_on_page
      @batch_part_on_other_page = @batch_size_on_other_page > 0

      @add_files_to_collection = params.fetch(:add_files_to_collection, '')

      respond_to do |format|
        format.html {}
        format.rss  { render layout: false }
        format.atom { render layout: false }
      end
    end

    private

      def query_solr
        search_results(params, search_params_logic)
      end
  end
end

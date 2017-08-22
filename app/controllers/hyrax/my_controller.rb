module Hyrax
  class MyController < ApplicationController
    include Hydra::Catalog
    include Hyrax::Collections::AcceptsBatches

    def self.configure_facets
      # clear facet's copied from the CatalogController
      blacklight_config.facet_fields = {}
      configure_blacklight do |config|
        # TODO: add a visibility facet (requires visibility to be indexed)
        config.add_facet_field IndexesWorkflow.suppressed_field, helper_method: :suppressed_to_status
        config.add_facet_field solr_name("admin_set", :facetable), limit: 5
        config.add_facet_field solr_name("resource_type", :facetable), limit: 5
      end
    end

    layout 'dashboard'

    include Blacklight::Configurable

    copy_blacklight_config_from(CatalogController)
    configure_facets

    before_action :authenticate_user!
    before_action :enforce_show_permissions, only: :show

    # include the render_check_all view helper method
    helper Hyrax::BatchEditsHelper
    # include the display_trophy_link view helper method
    helper Hyrax::TrophyHelper
    helper_method :suppressed_to_status

    def index
      # The user's collections for the "add to collection" form
      # TODO: could this be only on the My::WorksController?
      @user_collections = collections_service.search_results(:edit)

      @user = current_user
      (@response, @document_list) = query_solr
      prepare_instance_variables_for_batch_control_display

      respond_to do |format|
        format.html {}
        format.rss  { render layout: false }
        format.atom { render layout: false }
      end
    end

    def suppressed_to_status(value)
      case value
      when "false"
        "Published"
      else
        "In review"
      end
    end

    private

      def collections_service
        Hyrax::CollectionsService.new(self)
      end

      # TODO: Extract a presenter object that wrangles all of these instance variables.
      def prepare_instance_variables_for_batch_control_display
        # set up some parameters for allowing the batch controls to show appropriately
        max_batch_size = 80
        count_on_page = @document_list.count { |doc| batch.index(doc.id) }
        @disable_select_all = @document_list.count > max_batch_size
        @result_set_size = @response.response["numFound"]
        @empty_batch = batch.empty?
        @all_checked = (count_on_page == @document_list.count)
        @add_works_to_collection = params.fetch(:add_works_to_collection, '')
      end

      def query_solr
        search_results(params)
      end
  end
end

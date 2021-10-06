# frozen_string_literal: true
module Hyrax
  class MyController < ApplicationController
    extend Deprecation
    include Hydra::Catalog
    include Hyrax::Collections::AcceptsBatches

    # Define filter facets that apply to all repository objects.
    def self.configure_facets
      # clear facet's copied from the CatalogController
      blacklight_config.facet_fields = {}
      configure_blacklight do |config|
        # TODO: add a visibility facet (requires visibility to be indexed)
        config.add_facet_field "visibility_ssi",
                               helper_method: :visibility_badge,
                               limit: 5, label: I18n.t('hyrax.dashboard.my.heading.visibility')
        config.add_facet_field IndexesWorkflow.suppressed_field, helper_method: :suppressed_to_status
        config.add_facet_field "resource_type_sim", limit: 5
      end
    end

    with_themed_layout 'dashboard'

    include Blacklight::Configurable

    copy_blacklight_config_from(CatalogController)
    configure_facets

    before_action :authenticate_user!
    load_and_authorize_resource only: :show,
                                instance_name: :collection,
                                class: Hyrax.config.collection_model

    # include the render_check_all view helper method
    helper Hyrax::BatchEditsHelper
    # include the display_trophy_link view helper method
    helper Hyrax::TrophyHelper

    def index
      @user = current_user
      (@response, @document_list) = search_service.search_results
      prepare_instance_variables_for_batch_control_display

      respond_to do |format|
        format.html {}
        format.rss  { render layout: false }
        format.atom { render layout: false }
      end
    end

    private

    # TODO: Extract a presenter object that wrangles all of these instance variables.
    def prepare_instance_variables_for_batch_control_display
      # set up some parameters for allowing the batch controls to show appropriately
      max_batch_size = Hyrax.config.range_for_number_of_results_to_display_per_page.max
      count_on_page = @document_list.count { |doc| batch.index(doc.id) }
      @disable_select_all = @document_list.count > max_batch_size
      @result_set_size = @response.response["numFound"]
      @empty_batch = batch.empty?
      @all_checked = (count_on_page == @document_list.count)
      @add_works_to_collection = params.fetch(:add_works_to_collection, '')
      @add_works_to_collection_label = params.fetch(:add_works_to_collection_label, '')
    end

    def query_solr
      search_service.search_results
    end
    deprecation_deprecate :query_solr

    def search_service
      Hyrax::SearchService.new(config: blacklight_config, user_params: params, scope: self)
    end
  end
end

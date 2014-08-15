# -*- coding: utf-8 -*-
class CollectionsController < ApplicationController
  include Hydra::CollectionsControllerBehavior
  include Blacklight::Catalog::SearchContext
  include BlacklightAdvancedSearch::ParseBasicQ
  include BlacklightAdvancedSearch::Controller
  include Sufia::Breadcrumbs
  prepend_before_filter :normalize_identifier, except: [:index, :create, :new]
  before_filter :filter_docs_with_read_access!, except: :show
  before_filter :has_access?, except: :show
  before_filter :initialize_fields_for_edit, only: [:edit, :new]
  before_filter :build_breadcrumbs, only: [:edit, :show]
  CollectionsController.solr_search_params_logic += [:add_access_controls_to_solr_params]

  layout "sufia-one-column"

  protected 

  def query_collection_members
    flash[:notice]=nil if flash[:notice] == "Select something first"
    query = params[:cq]

    #merge in the user parameters and the attach the collection query
    solr_params =  (params.symbolize_keys).merge(q: query)

    # run the solr query to find the collections
    (@response, @member_docs) = get_search_results(solr_params)
  end

  def after_destroy(id)
    respond_to do |format|
      format.html { redirect_to sufia.dashboard_collections_path, notice: 'Collection was successfully deleted.' }
      format.json { render json: {id: id}, status: :destroyed, location: @collection }
    end
  end
  
  def initialize_fields_for_edit
    @collection.initialize_fields
  end

  def _prefixes
    @_prefixes ||= super + ['catalog']
  end

end

module Worthwhile
  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::CollectionsControllerBehavior
    include Blacklight::Catalog::SearchContext
    include Worthwhile::ThemedLayoutController
    include Hydra::AccessControlsEnforcement

    included do
      before_filter :filter_docs_with_read_access!, except: [:show, :new]
      # CollectionsController.search_params_logic += [:add_access_controls_to_solr_params]
      helper Worthwhile::CatalogHelper
    end

    # For some reason this is not inheriting from ApplicationControllerBehavior via subclassing ApplicationController
    def current_ability
      user_signed_in? ? current_user.ability : super
    end

    def collections_search_builder_class
      Worthwhile::CollectionSearchBuilder
    end

    def collection_member_search_builder_class
      Worthwhile::CollectionSearchBuilder
    end

    def collection_member_search_logic
      super + [:add_access_controls_to_solr_params]
    end

    protected

    # Override Hydra::PolicyAwareAccessControlsEnforcement
    def gated_discovery_filters
      return [] if current_user && (current_user.groups.include? 'admin')
      super
    end

    def query_collection_members
      flash[:notice]=nil if flash[:notice] == "Select something first"
      query = params[:cq]

      #merge in the user parameters and the attach the collection query
      solr_params =  (params.symbolize_keys).merge(q: query)

      # run the solr query to find the collections
      (@response, @member_docs) = search_results(solr_params)
    end

    def after_destroy(id)
      respond_to do |format|
        format.html { redirect_to main_app.root_path, notice: 'Collection was successfully deleted.' }
        format.json { render json: {id: id}, status: :destroyed, location: @collection }
      end
    end

    def initialize_fields_for_edit
      @collection.initialize_fields
    end

    # If they've selected "owner=mine" then restrict to files I have edit access to
    def discovery_permissions
      if params[:owner]=="mine"
        ["edit"]
      else
        super
      end
    end

    # Include 'catalog' and 'curation_concern/base' in search path for views
    def _prefixes
      @_prefixes ||= super + ['catalog', 'curation_concern/base']
    end

  end
end

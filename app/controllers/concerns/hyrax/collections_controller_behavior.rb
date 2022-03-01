# frozen_string_literal: true
module Hyrax
  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Blacklight::AccessControls::Catalog
    include Blacklight::Base

    included do
      # include the display_trophy_link view helper method
      helper Hyrax::TrophyHelper

      # This is needed as of BL 3.7
      copy_blacklight_config_from(::CatalogController)

      class_attribute :presenter_class,
                      :form_class,
                      :single_item_search_builder_class,
                      :membership_service_class,
                      :parent_collection_query_service

      self.presenter_class = Hyrax::CollectionPresenter

      # The search builder to find the collection
      self.single_item_search_builder_class = SingleCollectionSearchBuilder
      # The search builder to find the collections' members
      self.membership_service_class = Collections::CollectionMemberSearchService
      # A search service to use in finding parent collections
      self.parent_collection_query_service = Collections::NestedCollectionQueryService
    end

    def show
      @curation_concern = @collection # we must populate curation_concern
      presenter
      query_collection_members
    end

    def collection
      action_name == 'show' ? @presenter : @collection
    end

    private

    def presenter
      @presenter ||= presenter_class.new(curation_concern, current_ability)
    end

    def curation_concern
      # Query Solr for the collection.
      # run the solr query to find the collection members
      response, _docs = search_service.search_results
      curation_concern = response.documents.first
      raise CanCan::AccessDenied unless curation_concern
      curation_concern
    end

    def search_service
      Hyrax::SearchService.new(config: blacklight_config, user_params: params.except(:q, :page), scope: self, search_builder_class: single_item_search_builder_class)
    end

    # Instantiates the search builder that builds a query for a single item
    # this is useful in the show view.
    def single_item_search_builder
      search_service.search_builder
    end
    deprecation_deprecate :single_item_search_builder

    def collection_params
      form_class.model_attributes(params[:collection])
    end

    # Include 'catalog' and 'hyrax/base' in the search path for views, while prefering
    # our local paths. Thus we are unable to just override `self.local_prefixes`
    def _prefixes
      @_prefixes ||= super + ['catalog', 'hyrax/base']
    end

    def query_collection_members
      load_member_works
      load_member_subcollections if collection.collection_type.nestable?
      load_parent_collections if collection.collection_type.nestable? && action_name == 'show'
    end

    # Instantiate the membership query service
    def collection_member_service
      @collection_member_service ||= membership_service_class.new(scope: self, collection: collection, params: params_for_query)
    end

    def member_works
      @response = collection_member_service.available_member_works
      @member_docs = @response.documents
      @members_count = @response.total
    end
    alias load_member_works member_works

    ##
    # Handles paged loading for parent collections.
    #
    # @param the query service to use when searching for the parent collections.
    #   uses the class attribute +parent_collection_query_service+ by default.
    def parent_collections(query_service: self.class.parent_collection_query_service)
      page = params[:parent_collection_page].to_i

      collection.parent_collections =
        query_service.parent_collections(child: collection_object,
                                         scope: self,
                                         page: page)
    end
    alias load_parent_collections parent_collections

    ##
    # @note this is here because, though we want to load and authorize the real
    #   collection for show views, for apparently historical reasons,
    #   {#collection} is overridden to access `@presenter`. this should probably
    #   be deprecated and callers encouraged to use `@collection` but the scope
    #   and impact of that change needs more evaluation.
    def collection_object
      action_name == 'show' ? @collection : collection
    end

    def member_subcollections
      results = collection_member_service.available_member_subcollections
      @subcollection_solr_response = results
      @subcollection_docs = results.documents
      @subcollection_count = @presenter.subcollection_count = results.total
    end
    alias load_member_subcollections member_subcollections

    # You can override this method if you need to provide additional inputs to the search
    # builder. For example:
    #   search_field: 'all_fields'
    # @return <Hash> the inputs required for the collection member query service
    def params_for_query
      params.merge(q: params[:cq])
    end
  end
end

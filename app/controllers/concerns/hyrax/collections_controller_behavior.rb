module Hyrax
  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Blacklight::AccessControls::Catalog
    include Blacklight::Base

    included do
      before_action :filter_docs_with_read_access!, except: :show

      include Hyrax::Collections::AcceptsBatches

      # include the render_check_all view helper method
      helper Hyrax::BatchEditsHelper
      # include the display_trophy_link view helper method
      helper Hyrax::TrophyHelper

      # This is needed as of BL 3.7
      copy_blacklight_config_from(::CatalogController)

      class_attribute :presenter_class,
                      :form_class,
                      :single_item_search_builder_class,
                      :member_search_builder_class

      alias_method :collection_search_builder_class, :single_item_search_builder_class
      deprecation_deprecate collection_search_builder_class: "use single_item_search_builder_class instead"

      alias_method :collection_member_search_builder_class, :member_search_builder_class
      deprecation_deprecate collection_member_search_builder_class: "use member_search_builder_class instead"

      self.presenter_class = Hyrax::CollectionPresenter

      # The search builder to find the collection
      self.single_item_search_builder_class = SingleCollectionSearchBuilder
      # The search builder to find the collections' members
      self.member_search_builder_class = Hyrax::CollectionMemberSearchBuilder
    end

    def show
      presenter
      query_collection_members
    end

    def collection
      action_name == 'show' ? @presenter : @collection
    end

    private

      def presenter
        @presenter ||= begin
          # Query Solr for the collection.
          # run the solr query to find the collection members
          response = repository.search(single_item_search_builder.query)
          curation_concern = response.documents.first
          raise CanCan::AccessDenied unless curation_concern
          presenter_class.new(curation_concern, current_ability)
        end
      end

      # Instantiates the search builder that builds a query for a single item
      # this is useful in the show view.
      def single_item_search_builder
        single_item_search_builder_class.new(self).with(params.except(:q, :page))
      end

      alias collection_search_builder single_item_search_builder
      deprecation_deprecate collection_search_builder: "use single_item_search_builder instead"

      # Instantiates the search builder that builds a query for items that are
      # members of the current collection. This is used in the show view.
      def member_search_builder
        @member_search_builder ||= member_search_builder_class.new(self)
      end

      alias collection_member_search_builder member_search_builder
      deprecation_deprecate collection_member_search_builder: "use member_search_builder instead"

      def collection_params
        form_class.model_attributes(params[:collection])
      end

      # Queries Solr for members of the collection.
      # Populates @response and @member_docs similar to Blacklight Catalog#index populating @response and @documents
      def query_collection_members
        params[:q] = params[:cq]
        @response = repository.search(query_for_collection_members)
        @member_docs = @response.documents
      end

      # @return <Hash> a representation of the solr query that find the collection members
      def query_for_collection_members
        member_search_builder.with(params_for_members_query).query
      end

      # You can override this method if you need to provide additional inputs to the search
      # builder. For example:
      #   search_field: 'all_fields'
      # @return <Hash> the inputs required for the collection member search builder
      def params_for_members_query
        params.merge(q: params[:cq])
      end

      # Include 'catalog' and 'hyrax/base' in the search path for views, while prefering
      # our local paths. Thus we are unable to just override `self.local_prefixes`
      def _prefixes
        @_prefixes ||= super + ['catalog', 'hyrax/base']
      end
  end
end

module Hyrax
  module Collections
    # Responsible for retrieving collection members
    class CollectionMemberService
      attr_reader :scope, :params, :collection
      delegate :repository, to: :scope

      # @param scope [#repository] Typically a controller object which responds to :repository
      # @param [::Collection]
      # @param [ActionController::Parameters] query params
      def initialize(scope:, collection:, params:)
        @scope = scope
        @collection = collection
        @params = params
      end

      # @api public
      #
      # Collections which are members of the given collection
      # @return [Blacklight::Solr::Response] {up to 50 solr documents}
      def available_member_subcollections
        query_solr(query_builder: subcollections_search_builder, query_params: params_for_subcollections)
      end

      # @api public
      #
      # Works which are members of the given collection
      # @return [Blacklight::Solr::Response]
      def available_member_works
        query_solr(query_builder: works_search_builder, query_params: params)
      end

      # @api public
      #
      # Work ids of the works which are members of the given collection
      # @return [Blacklight::Solr::Response]
      def available_member_work_ids
        query_solr_with_field_selection(query_builder: work_ids_search_builder, fl: 'id')
      end

      private

      # @api private
      #
      # set up a member search builder for works only
      # @return [CollectionMemberSearchBuilder] new or existing
      def works_search_builder
        @works_search_builder ||= Hyrax::CollectionMemberSearchBuilder.new(scope: scope, collection: collection, search_includes_models: :works)
      end

      # @api private
      #
      # set up a member search builder for collections only
      # @return [CollectionMemberSearchBuilder] new or existing
      def subcollections_search_builder
        @subcollections_search_builder ||= Hyrax::CollectionMemberSearchBuilder.new(scope: scope, collection: collection, search_includes_models: :collections)
      end

      # @api private
      #
      # set up a member search builder for returning work ids only
      # @return [CollectionMemberSearchBuilder] new or existing
      def work_ids_search_builder
        @work_ids_search_builder ||= Hyrax::CollectionMemberSearchBuilder.new(scope: scope, collection: collection, search_includes_models: :works)
      end

      # @api private
      #
      def query_solr(query_builder:, query_params:)
        repository.search(query_builder.with(query_params).query)
      end

      # @api private
      #
      def query_solr_with_field_selection(query_builder:, fl:)
        repository.search(query_builder.merge(fl: fl).query)
      end

      # @api private
      #
      # Blacklight pagination still needs to be overridden and set up for the subcollections.
      # @return <Hash> the additional inputs required for the subcollection member search builder
      def params_for_subcollections
        # To differentiate current page for works vs subcollections, we have to use a sub_collection_page
        # param. Map this to the page param before querying for subcollections, if it's present
        params[:page] = params.delete(:sub_collection_page)
        params
      end
    end
  end
end

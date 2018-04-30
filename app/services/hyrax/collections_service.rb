module Hyrax
  class CollectionsService
    attr_reader :context

    class_attribute :list_search_builder_class
    self.list_search_builder_class = Hyrax::CollectionSearchBuilder

    # @param [#repository,#blacklight_config,#current_ability] context
    def initialize(context)
      @context = context
    end

    # @param [Symbol] access :read or :edit or :deposit
    def search_results(access)
      builder = list_search_builder(access)
      response = context.repository.search(builder)
      response.documents
    end

    private

      def list_search_builder(access)
        builder = list_search_builder_class.new(context)
                                           .rows(Hyrax.config.collection_query_limit)
                                           .with_access(access)
        # return only the originating collection if one was specified
        add_to_collection_id = context.params[:add_works_to_collection]
        builder.where(id: add_to_collection_id) unless add_to_collection_id.nil?
        builder
      end
  end
end

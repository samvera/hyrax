module Hyrax
  class AdminSetsController < ApplicationController
    include Hyrax::CollectionsControllerBehavior

    self.presenter_class = Hyrax::AdminSetPresenter

    class_attribute :list_search_builder_class

    self.list_search_builder_class = Hyrax::AdminSetSearchBuilder

    alias collections_search_builder_class list_search_builder_class
    deprecation_deprecate collections_search_builder_class: "use list_search_builder_class instead"

    # Used for the show action
    self.single_item_search_builder_class = Hyrax::SingleAdminSetSearchBuilder
    # Used to get the members for the show action
    self.member_search_builder_class = Hyrax::AdminSetMemberSearchBuilder

    # Override the default prefixes so that we use the collection partals.
    def self.local_prefixes
      ["hyrax/admin_sets", "hyrax/collections", 'catalog']
    end

    def index
      # run the solr query to find the collections
      query = list_search_builder.with(params).query
      @response = repository.search(query)
      @document_list = @response.documents
    end

    private

      def list_search_builder
        list_search_builder_class.new(self, :read)
      end

      alias collections_search_builder list_search_builder
      deprecation_deprecate collections_search_builder: "use list_search_builder instead"
  end
end

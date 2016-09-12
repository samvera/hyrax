module Sufia
  class AdminSetsController < ApplicationController
    include CurationConcerns::CollectionsControllerBehavior
    include Sufia::CollectionsControllerBehavior

    class_attribute :list_search_builder_class
    self.list_search_builder_class = CurationConcerns::AdminSetSearchBuilder

    # Override the default prefixes so that we use the collection partals.
    def _prefixes
      @_prefixes ||= ["sufia/admin_sets", "collections", 'catalog']
    end

    # Overriding the way that the search builder is initialized
    def collections_search_builder
      list_search_builder_class.new(self, :read)
    end
  end
end

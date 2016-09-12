module Sufia
  class AdminSetsController < ApplicationController
    include CurationConcerns::CollectionsControllerBehavior
    layout "sufia-one-column"

    self.presenter_class = Sufia::AdminSetPresenter

    self.list_search_builder_class = CurationConcerns::AdminSetSearchBuilder
    # Used for the show action
    self.single_item_search_builder_class = Sufia::SingleAdminSetSearchBuilder
    # Used to get the members for the show action
    self.member_search_builder_class = Sufia::AdminSetMemberSearchBuilder

    # Override the default prefixes so that we use the collection partals.
    def self.local_prefixes
      ["sufia/admin_sets", "collections", 'catalog']
    end

    private

      # Overriding the way that the search builder is initialized
      def list_search_builder
        list_search_builder_class.new(self, :read)
      end
  end
end

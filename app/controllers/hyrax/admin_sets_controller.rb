module Hyrax
  class AdminSetsController < ApplicationController
    include Hyrax::CollectionsControllerBehavior

    self.presenter_class = Hyrax::AdminSetPresenter

    self.list_search_builder_class = Hyrax::AdminSetSearchBuilder
    # Used for the show action
    self.single_item_search_builder_class = Hyrax::SingleAdminSetSearchBuilder
    # Used to get the members for the show action
    self.member_search_builder_class = Hyrax::AdminSetMemberSearchBuilder

    # Override the default prefixes so that we use the collection partals.
    def self.local_prefixes
      ["hyrax/admin_sets", "hyrax/collections", 'catalog']
    end

    private

      # Overriding the way that the search builder is initialized
      def list_search_builder
        list_search_builder_class.new(self, :read)
      end
  end
end

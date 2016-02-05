module Sufia
  module Catalog
    extend ActiveSupport::Concern
    included do
      # include the all_type_tab and link_to_select_collection view helper methods
      helper CurationConcerns::CatalogHelper, CurationConcerns::CollectionsHelper

      def search_builder_class
        Sufia::CatalogSearchBuilder
      end
    end
  end
end

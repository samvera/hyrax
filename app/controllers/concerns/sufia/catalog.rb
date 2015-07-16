module Sufia
  module Catalog
    extend ActiveSupport::Concern
    included do
      self.search_params_logic += [:only_works_and_collections, :show_works_or_works_that_contain_files]

      # include the all_type_tab and link_to_select_collection view helper methods
      helper CurationConcerns::CatalogHelper, CurationConcerns::CollectionsHelper
    end
  end
end

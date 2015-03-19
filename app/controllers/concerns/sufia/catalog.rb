module Sufia
  module Catalog
    extend ActiveSupport::Concern
    included do
      self.search_params_logic += [:only_generic_files_and_collections]
    end
  end
end

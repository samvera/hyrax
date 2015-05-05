module Sufia
  module Catalog
    extend ActiveSupport::Concern
    included do
      self.search_params_logic += [:only_works_and_collections]
    end
  end
end

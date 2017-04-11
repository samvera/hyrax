module Hyrax
  class SearchBuilder < ::SearchBuilder
    def initialize(*)
      Deprecation.warn(self, "Hyrax::SearchBuilder is deprecated and will be removed in Hyrax 3.0. Use ::SearchBuilder instead")
      super
    end
  end
end

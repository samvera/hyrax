module Hydra
  class SearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
    include Hydra::AccessControlsEnforcement

    def initialize(*)
      Deprecation.warn SearchBuilder, "Hydra::SearchBuilder is deprecated and will be removed in hydra-head 10.0. Instead add include Hydra::AccessControlsEnforcement to app/models/search_builder.rb"
      super
    end
  end
end

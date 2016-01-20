module Hydra
  class SearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
    include Hydra::AccessControlsEnforcement
  end
end

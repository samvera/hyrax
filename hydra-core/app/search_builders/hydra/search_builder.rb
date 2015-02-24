module Hydra
  class SearchBuilder < Blacklight::Solr::SearchBuilder
    include Hydra::AccessControlsEnforcement
  end
end

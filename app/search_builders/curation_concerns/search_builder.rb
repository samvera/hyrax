class CurationConcerns::SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include CurationConcerns::SearchFilters
  extend Deprecation
  def initialize(*)
    Deprecation.warn CurationConcerns::SearchBuilder, "CurationConcerns::SearchBuilder is deprecated and will be removed in CurationConcerns 1.0. Add CurationConcerns::SearchFilters to your own SearchBuilder instead"
    super
  end
end

class Worthwhile::CollectionSearchBuilder < Worthwhile::SearchBuilder

  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include Hydra::Collections::SearchBehaviors

end
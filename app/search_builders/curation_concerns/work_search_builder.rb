module CurationConcerns
  class WorkSearchBuilder < ::SearchBuilder
    include CurationConcerns::SingleResult
    include CurationConcerns::FilterSuppressedWithRoles
  end
end

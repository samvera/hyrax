module Hyrax
  class WorkSearchBuilder < ::SearchBuilder
    include SingleResult
    include FilterSuppressedWithRoles
  end
end

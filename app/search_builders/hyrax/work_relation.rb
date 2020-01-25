module Hyrax
  class WorkRelation < AbstractTypeRelation
    def allowable_types
      Hyrax.config.work_types
    end
  end
end

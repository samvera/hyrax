# frozen_string_literal: true
module Hyrax
  class WorkRelation < AbstractTypeRelation
    def allowable_types
      Hyrax.config.curation_concerns
    end
  end
end

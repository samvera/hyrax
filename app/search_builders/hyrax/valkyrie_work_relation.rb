# frozen_string_literal: true

module Hyrax
  class ValkyrieWorkRelation < ValkyrieAbstractTypeRelation
    def allowable_types
      Hyrax.config.curation_concerns
    end
  end
end

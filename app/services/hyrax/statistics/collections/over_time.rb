# frozen_string_literal: true
module Hyrax
  module Statistics
    module Collections
      class OverTime < Statistics::OverTime
        private

        def relation
          AbstractTypeRelation
            .new(allowable_types: [Hyrax.config.collection_class])
        end
      end
    end
  end
end

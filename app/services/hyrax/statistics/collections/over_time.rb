# frozen_string_literal: true
module Hyrax
  module Statistics
    module Collections
      class OverTime < Statistics::OverTime
        private

        def relation
          Hyrax.config.collection_class
        end
      end
    end
  end
end

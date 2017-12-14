module Hyrax
  module Statistics
    module Collections
      class OverTime < Statistics::OverTime
        private

          def search_builder
            Hyrax::CollectionSearchBuilder.new([:filter_models], self)
          end
      end
    end
  end
end

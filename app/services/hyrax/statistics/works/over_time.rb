module Hyrax
  module Statistics
    module Works
      class OverTime < Statistics::OverTime
        private

          def search_builder
            Hyrax::WorksSearchBuilder.new([:filter_models], self)
          end
      end
    end
  end
end

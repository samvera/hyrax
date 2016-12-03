module Hyrax
  module Statistics
    module Collections
      class OverTime < Statistics::OverTime
        private

          def relation
            Collection
          end
      end
    end
  end
end

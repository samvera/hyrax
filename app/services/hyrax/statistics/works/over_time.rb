module Hyrax
  module Statistics
    module Works
      class OverTime < Statistics::OverTime
        private

          def relation
            Hyrax::WorkRelation.new
          end
      end
    end
  end
end

module Sufia
  module Statistics
    module Works
      class OverTime < Statistics::OverTime
        private

          def relation
            Sufia::WorkRelation.new
          end
      end
    end
  end
end

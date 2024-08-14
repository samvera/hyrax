# frozen_string_literal: true
module Hyrax
  module Statistics
    module Works
      class OverTime < Statistics::OverTime
        def points
          Enumerator.new(size) do |y|
            x = @x_min
            while x <= @x_max
              y.yield [@x_output.call(x), point(@x_min, x)]
              x += @delta_x.days
            end
          end
        end

        private

        def relation
          Hyrax.config.disable_wings ? Hyrax::ValkyrieWorkRelation.new : Hyrax::WorkRelation.new
        end
      end
    end
  end
end

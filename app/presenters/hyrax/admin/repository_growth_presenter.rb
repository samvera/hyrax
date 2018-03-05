module Hyrax
  module Admin
    class RepositoryGrowthPresenter
      def initialize(time_period = 90)
        @x_min = Integer(time_period).days.ago.beginning_of_day
        @date_format = ->(x) { x.strftime('%F') }
      end

      def as_json(*)
        works.to_a.zip(collections.to_a).map do |e|
          { y: e.first.first, a: e.first.last, b: e.last.last }
        end
      end

      private

        def works
          Hyrax::Statistics::Works::OverTime.new(x_min: @x_min,
                                                 x_output: @date_format).points
        end

        def collections
          Hyrax::Statistics::Collections::OverTime.new(x_min: @x_min,
                                                       x_output: @date_format).points
        end
    end
  end
end

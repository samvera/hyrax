module Hyrax
  module Admin
    class RepositoryGrowthPresenter
      def initialize(time_period = 90)
        @x_min = Integer(time_period).days.ago.beginning_of_day
        @date_format = ->(x) { x.strftime('%F') }
      end

      def as_json(*)
        # Setup data for ChartKick
        works_list = { name: I18n.translate('hyrax.dashboard.analytics_collections.works'), data: [] }
        collections_list = { name: I18n.translate('hyrax.dashboard.analytics_collections.title'), data: [] }

        works.to_a.zip(collections.to_a).map do |e|
          works_list[:data] << [e.first.first, e.first.last]
          collections_list[:data] << [e.first.first, e.last.last]
        end

        [works_list, collections_list]
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

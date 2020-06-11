# frozen_string_literal: true
module Hyrax
  module ChartsHelper
    # @example A chart with a drilldown
    #   {
    #     "First" => {
    #       "Second" => 3,
    #       "Third" => 3
    #     }
    #   }
    # @example A chart without a drilldown
    #   {
    #     "First" => 3,
    #     "Second" => 4
    #   }
    def hash_to_chart(data)
      data = ChartData.new(data)
      {
        drilldown: { series: data.drilldown },
        series: data.series
      }
    end
  end
end

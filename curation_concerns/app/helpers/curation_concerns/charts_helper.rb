module CurationConcerns
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
      data = ::CurationConcerns::ChartData.new(data)
      {
        drilldown: { series: data.drilldown },
        series: data.series
      }
    end
  end
end

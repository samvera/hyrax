module CurationConcerns
  module ChartsHelper
    def hash_to_chart(data)
      drilldowns = data.each_with_object([]) do |(k, v), arr|
        arr << { name: k, id: k, data: v.to_a } if v.is_a?(Hash)
      end
      data = data.each_with_object([]) do |(k, v), arr|
        arr << if v.is_a?(Hash)
                 { name: k, y: v.values.inject(&:+), drilldown: k }
               else
                 { name: k, y: v }
               end
      end
      { drilldown: { series: drilldowns }, series: data }
    end
  end
end

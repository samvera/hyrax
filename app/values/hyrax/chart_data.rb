module Hyrax
  class ChartData
    attr_reader :data
    def initialize(data)
      @data = data
    end

    def drilldown
      data.each_with_object([]) do |(k, v), arr|
        arr << Value.new(k, v).drilldown_value
      end.compact
    end

    def series
      data.each_with_object([]) do |(k, v), arr|
        arr << Value.new(k, v).series_value
      end
    end

    class Value
      def initialize(key, value)
        @key = key
        @value = value
      end

      def series_value
        if @value.is_a?(Hash)
          drilldown_hash
        else
          series_hash
        end
      end

      def drilldown_value
        return nil unless @value.is_a?(Hash)
        {
          name: @key,
          id: @key,
          data: @value.to_a
        }
      end

      private

        def drilldown_hash
          {
            name: @key,
            y: @value.values.inject(&:+),
            drilldown: @key
          }
        end

        def series_hash
          {
            name: @key,
            y: @value
          }
        end
    end
  end
end

module Hyrax
  module Analytics
    class Results

      attr_accessor :results

      def initialize(results)
        @results ||= results
      end

      def all
        results.inject(0) {|sum, a| sum + a[1]}
      end
  
      def day(date = Date.today)
        start_date = date.at_beginning_of_day
        end_date = date.at_end_of_day
        range_results = []
        results.each do |result| 
          if (start_date..end_date).cover?(result[0])
            range_results.push(result)  
          end
        end
        range_results.inject(0) {|sum, a| sum + a[1]}
      end
  
      def week(date = Date.today)
        start_date = date.at_beginning_of_week
        end_date = date.at_end_of_week
        range_results = []
        results.each do |result| 
          if (start_date..end_date).cover?(result[0])
            range_results.push(result)  
          end
        end
        range_results.inject(0) {|sum, a| sum + a[1]}
      end

      def month(date = Date.today)
        start_date = date.at_beginning_of_month
        end_date = date.at_end_of_month
        range_results = []
        results.each do |result| 
          if (start_date..end_date).cover?(result[0])
            range_results.push(result)  
          end
        end
        range_results.inject(0) {|sum, a| sum + a[1]}
      end
  
      def year(date = Date.today)
        start_date = date.at_beginning_of_year
        end_date = date.at_end_of_year
        range_results = []
        results.each do |result| 
          if (start_date..end_date).cover?(result[0])
            range_results.push(result)  
          end
        end
        range_results.inject(0) {|sum, a| sum + a[1]}
      end      

      def range(start_date = Time.zone.today-1.month, end_date = Time.zone.today)
        range_results = []
        results.each do |result| 
          if (start_date..end_date).cover?(result[0])
            range_results.push(result)  
          end
        end
        range_results.inject(0) {|sum, a| sum + a[1]}
      end
      
    end
  end
end
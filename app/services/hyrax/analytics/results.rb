# frozen_string_literal: true
module Hyrax
  module Analytics
    class Results
      require 'csv'

      attr_accessor :results

      def initialize(results)
        @results ||= results
      end

      def all
        results.inject(0) { |sum, a| sum + a[1] }
      end

      def day(date = Time.zone.today)
        start_date = date.at_beginning_of_day
        end_date = date.at_end_of_day
        range_results = []
        results.each do |result|
          range_results.push(result) if (start_date..end_date).cover?(result[0])
        end
        range_results.inject(0) { |sum, a| sum + a[1] }
      end

      def week(date = Time.zone.today)
        start_date = date.at_beginning_of_week
        end_date = date.at_end_of_week
        range_results = []
        results.each do |result|
          range_results.push(result) if (start_date..end_date).cover?(result[0])
        end
        range_results.inject(0) { |sum, a| sum + a[1] }
      end

      def month(date = Time.zone.today)
        start_date = date.at_beginning_of_month
        end_date = date.at_end_of_month
        range_results = []
        results.each do |result|
          range_results.push(result) if (start_date..end_date).cover?(result[0])
        end
        range_results.inject(0) { |sum, a| sum + a[1] }
      end

      def year(date = Time.zone.today)
        start_date = date.at_beginning_of_year
        end_date = date.at_end_of_year
        range_results = []
        results.each do |result|
          range_results.push(result) if (start_date..end_date).cover?(result[0])
        end
        range_results.inject(0) { |sum, a| sum + a[1] }
      end

      def range(start_date = Time.zone.today - 1.month, end_date = Time.zone.today)
        range_results = []
        results.each do |result|
          range_results.push(result) if (start_date..end_date).cover?(result[0])
        end
        range_results.inject(0) { |sum, a| sum + a[1] }
      end

      def to_csv
        results.inject([]) { |csv, row| csv << CSV.generate_line(row) }.join("")
      end

      def list
        results.inject([]) { |line, row| line << row }.reverse
      end

      def to_flot
        fields = [:date, :pageviews]
        results.map { |row| fields.zip(row).to_h }
      end

      def each
        results.each do |result|
          yield({ date: result[0], pageviews: result[1] })
        end
      end
    end
  end
end

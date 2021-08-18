# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module Pageviews
        extend Legato::Model

        metrics :pageviews
        dimensions :page_path_level1, :page_path, :date

        filter(:collections) { |_page_path_level1| contains(:pagePathLevel1, 'collections') }
        filter(:works) { |_page_path_level1| contains(:pagePathLevel1, 'concern') }
        filter :for_path, &->(path) { contains(:pagePath, path) }

        def self.results_array(response)
          results = []
          response.to_a.each do |result|
            results.push([result.date.to_date, result.pageviews.to_i])
          end
          Hyrax::Analytics::Results.new(results)
        end

        def self.all(profile, start_date, end_date)
          response = Pageviews.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: ['-date'])
          results_array(response)
        end

        def self.collections(profile, start_date, end_date)
          response = Pageviews.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: ['-date']).collections
          results_array(response)
        end

        def self.works(profile, start_date, end_date)
          response = Pageviews.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: ['-date']).works
          results_array(response)
        end

        def self.page(profile, start_date, end_date, path)
          response = Pageviews.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: ['-date']).for_path(path)
          results_array(response)
        end
      end
    end
  end
end

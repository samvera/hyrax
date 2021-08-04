module Hyrax
  module Analytics
    module Google
      module PageviewsMonthly
        extend Legato::Model

        metrics :pageviews
        dimensions :month, :year

        def self.query(profile, start_date, end_date)
          results = PageviewsMonthly.results(profile,
                            :start_date => start_date,
                            :end_date => end_date, 
                            :sort => ['year', 'month'])
          results_hash = {}
          results.each do |result| 
            month_year = "#{result.year}-#{result.month}"
            results_hash[month_year] = result.pageviews
            end
          results_hash
        end

      end
    end
  end
end
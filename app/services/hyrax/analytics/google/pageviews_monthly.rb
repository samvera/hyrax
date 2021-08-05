module Hyrax
  module Analytics
    module Google
      module PageviewsMonthly
        extend Legato::Model

        metrics :pageviews
        dimensions :month, :year, :page_path_level1

        filter(:collections) {|page_path_level1| contains(:pagePathLevel1, 'collections')}
        filter(:works) {|page_path_level1| contains(:pagePathLevel1, 'concern')}

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

        def self.works(profile, start_date, end_date)
          results = PageviewsMonthly.results(profile,
                            :start_date => start_date,
                            :end_date => end_date, 
                            :sort => ['year', 'month']).works
          results_hash = {}
          results.each do |result| 
            month_year = "#{result.year}-#{result.month}"
            results_hash[month_year] = result.pageviews
          end
          results_hash
        end
        
        def self.collections(profile, start_date, end_date)
          results = PageviewsMonthly.results(profile,
                            :start_date => start_date,
                            :end_date => end_date, 
                            :sort => ['year', 'month']).collections
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
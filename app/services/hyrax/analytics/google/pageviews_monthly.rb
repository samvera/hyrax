module Hyrax
  module Analytics
    module Google
      module PageviewsMonthly
        extend Legato::Model

        metrics :pageviews
        dimensions :month, :year

        def self.query(profile, start_date, end_date)
          PageviewsMonthly.results(profile,
                            :start_date => start_date,
                            :end_date => end_date, 
                            :sort => ['year', 'month'])
        end

      end
    end
  end
end
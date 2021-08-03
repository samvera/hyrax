module Hyrax
  module Analytics
    
    def self.provider
      "Hyrax::Analytics::#{Hyrax.config.analytics_provider.to_s.capitalize}".constantize
    end
       
    # Period Options = "day, week, month, year, range"
    # Date Format = "2021-01-01,2021-01-31"
    # Date "magic keywords" = "today, yesterday, lastX (number), lastWeek, lastMonth or lastYear"
    # Example:  Last 6 weeks:   period: week, date: last6

    def self.pageviews(period = 'day', date = 'today')
      provider.pageviews(period, date)
    end

    def self.pageviews_monthly(period = 'day', date = 'today')
      provider.pageviews_monthly(period, date)
    end
  
    def self.new_visitors(period = 'day', date = 'today')
      provider.new_visitors(period, date)
    end
    
    def self.returning_visitors(period = 'day', date = 'today')
      provider.returning_visitors(period, date)
    end

    def self.total_visitors(period = 'day', date = 'today')
      provider.total_visitors(period, date)
    end

    def self.unique_visitors(period = 'month', date = 'today')
      provider.unique_visitors(period, date)
    end
    
    def self.pageviews_by_url(url, period = 'year', date = 'today')
      provider.pageviews_by_url(url, period, date)
    end
    
  end
end

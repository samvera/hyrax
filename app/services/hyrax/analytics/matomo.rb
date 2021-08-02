# frozen_string_literal: true

module Hyrax
  module Analytics
    module Matomo 

      MATOMO_BASE_URL = Hyrax.config.matomo_base_url
      MATOMO_SITE_ID = Hyrax.config.matomo_site_id 
      MATOMO_AUTH_TOKEN = Hyrax.config.matomo_auth_token
      
      def self.pageviews(period, date)
        method = 'Actions.get'
        response = api_params(method, period, date, nil)
        response['nb_pageviews']
      end

      def self.new_visitors(period, date)
        method = 'VisitFrequency.get'
        response = api_params(method, period, date, nil)
        response["nb_visits_new"]
      end

      def self.returning_visitors(period, date)
        method = 'VisitFrequency.get'
        response = api_params(method, period, date, nil)
        response["nb_visits_returning"]
      end

      def self.total_visitors(period, date)
        method = 'VisitFrequency.get'
        response = api_params(method, period, date, nil)
        total = response["nb_visits_returning"].to_i + response["nb_visits_new"].to_i 
      end

      def self.unique_visitors(period, date)
        method = 'VisitsSummary.getUniqueVisitors'
        response = api_params(method, period, date, nil)
        response['value']
      end
  
      def self.pageviews_by_url(period, date, url)
        method = 'Actions.getPageUrl'
        response = api_params(method, period, date, nil)
        response.count == 0 ? 0 : response.first["nb_visits"]
      end
      
      private
      
        def self.get(params)
          response = Faraday.get(MATOMO_BASE_URL, params)
          return [] if response.status != 200
          response = JSON.parse(response.body)
        end
        
        def self.api_params(method, period, date, url)
          params = {
            module: "API",
            idSite: MATOMO_SITE_ID,
            method: method,
            period: period,
            date: date,
            url: url,
            format: "JSON",
            token_auth: MATOMO_AUTH_TOKEN
          }
          response = self.get(params)
        end

        def self.date_range(start_date, end_date)
          date_format = "%Y-%m-%d"
          end_date = end_date || Date.today
          start_date = start_date || end_date - 30.days
          {
            date: start_date.strftime(date_format) + "," + end_date.strftime(date_format)
          }
        end
      
    end 
  end 
end
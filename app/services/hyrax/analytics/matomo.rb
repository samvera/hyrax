# frozen_string_literal: true

module Hyrax
  module Analytics
    module Matomo
      extend ActiveSupport::Concern

      # rubocop:disable Metrics/BlockLength
      class_methods do
        # Loads configuration options from config/analytics.yml. Expected structure:
        # `analytics:`
        # `  matomo:`
        # `    base_url: <%= ENV['MATOMOT_BASE_URL']`
        # `    site_id: <%= ENV['MATOMOT_SITE_ID']`
        # `    auth_token: <%= ENV['MATOMOT_AUTH_TOKEN']`
        # @return [Config]
        def config
          @config ||= Config.load_from_yaml
        end

        class Config
          def self.load_from_yaml
            filename = Rails.root.join('config', 'analytics.yml')
            yaml = YAML.safe_load(ERB.new(File.read(filename)).result)
            unless yaml
              Rails.logger.error("Unable to fetch any keys from #{filename}.")
              return new({})
            end
            new yaml.fetch('analytics')&.fetch('matomo')
          end

          REQUIRED_KEYS = %w[base_url site_id auth_token].freeze

          def initialize(config)
            @config = config
          end

          # @return [Boolean] are all the required values present?
          def valid?
            config_keys = @config.keys
            REQUIRED_KEYS.all? { |required| config_keys.include?(required) }
          end

          REQUIRED_KEYS.each do |key|
            class_eval %{ def #{key};  @config.fetch('#{key}'); end }
          end
        end

        # Period Options = "day, week, month, year, range"
        # Date Format = "2021-01-01,2021-01-31"
        # Date "magic keywords" = "today, yesterday, lastX (number), lastWeek, lastMonth or lastYear"
        # Example: Last 6 weeks: period: week, date: last6

        def works_downloads(period = 'month', date = 'today')
          # TODO(alishaevn): fill out this method with the correct code!!
          # this code is just a copy of other code on the page
          # so the report pages will load

          method = 'VisitsSummary.getActions'
          response = api_params(method, period, date, nil)
          response
        end

        def pageviews_monthly(period = 'month', date = 'today')
          method = 'VisitsSummary.getActions'
          response = api_params(method, period, date, nil)
          response
        end

        def collections_pageviews_monthly(period = 'month', date = 'today')
          # TODO(alishaevn): fill out this method with the correct code!!
          # this code is just a copy of other code on the page
          # so the report pages will load

          method = 'Actions.getPageUrl'
          response = api_params(method, period, date, nil)
          response
        end

        def works_pageviews_monthly(period = 'month', date = 'today')
          # TODO(alishaevn): fill outworks_pageviews_monthly this method with the correct code!!
          # this code is just a copy of other code on the page
          # so the report pages will load

          method = 'Actions.getPageUrls'
          additional_params = {label: "concern"}
          response = api_params(method, period, date, additional_params)
          response
        end

        def pageviews(period = 'month', date = 'today')
          method = 'Actions.get'
          response = api_params(method, period, date, nil)
          response['nb_pageviews']
        end

        def works_pageviews(period = 'month', date = 'today')
          method = 'Actions.getPageUrls'
          additional_params = {label: 'concern'}
          response = api_params(method, period, date, additional_params)
          response.count.zero? ? 0 : response.first['nb_hits'].to_i
        end

        def collections_pageviews(period = 'month', date = 'today')
          method = 'Actions.getPageUrls'
          additional_params = {label: 'collections'}
          response = api_params(method, period, date, additional_params)
          response.count.zero? ? 0 : response.first['nb_hits'].to_i
        end

        def new_visitors(period = 'month', date = 'today')
          method = 'VisitFrequency.get'
          response = api_params(method, period, date, nil)
          response["nb_visits_new"]
        end

        def returning_visitors(period = 'month', date = 'today')
          method = 'VisitFrequency.get'
          response = api_params(method, period, date, nil)
          response["nb_visits_returning"]
        end

        def total_visitors(period = 'month', date = 'today')
          method = 'VisitFrequency.get'
          response = api_params(method, period, date, nil)
          response["nb_visits_returning"].to_i + response["nb_visits_new"].to_i
        end

        def unique_visitors(period = 'month', date = 'today')
          method = 'VisitsSummary.getUniqueVisitors'
          response = api_params(method, period, date, nil)
          response['value']
        end

        def top_collections(period = 'month', date = 'today')
          # TODO(alishaevn): fill out this method with the correct code!!
          # this code is just a copy of other code on the page
          # so the report pages will load

          method = 'Actions.getPageUrl'
          response = api_params(method, period, date, nil)
          response
        end

        def top_works(period = 'month', date = 'today')
          # TODO(alishaevn): fill out this method with the correct code!!
          # this code is just a copy of other code on the page
          # so the report pages will load

          method = 'Actions.getPageTitles'
          response = api_params(method, period, date, nil)
          response
        end

        def pageviews_by_url(period = 'month', date = 'today', url=nil)
          method = 'Actions.getPageUrl'
          additional_params = {url: url}
          response = api_params(method, period, date, nil)
          response.count.zero? ? 0 : response.first["nb_visits"]
        end

        def get(params)
          response = Faraday.get(config.base_url, params)
          return [] if response.status != 200
          JSON.parse(response.body)
        end    

        def api_params(method, period, date, additional_params)
          params = {
            module: "API",
            idSite: config.site_id,
            method: method,
            period: period,
            date: date,
            format: "JSON",
            token_auth: config.auth_token
          }
          params.merge!(additional_params) if additional_params
          get(params)
        end
      end
    end
  end
end

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
            class_eval %{ def #{key}; @config.fetch('#{key}'); end }
          end
        end

        # Period Options = "day, week, month, year, range"
        # Date Format = "2021-01-01,2021-01-31"
        # Date "magic keywords" = "today, yesterday, lastX (number), lastWeek, lastMonth or lastYear"
        # Example: Last 6 weeks: period: week, date: last6

        def default_date_range
          "#{Hyrax.config.analytics_start_date},#{Time.zone.today}"
        end

        def downloads(ref = 'all', date = default_date_range)
          if ref == 'all'
            segment = 'eventCategory==Files;eventAction==Downloaded'
            additional_params = { segment: segment }
            response = api_params('Events.getName', 'day', date, additional_params)
            results_array(response, 'nb_events')
          else
            send(:downloads_filtered, ref, date)
          end
        end

        def downloads_filtered(ref, date)
          segment = "eventCategory==#{ref.titleize};eventAction==Downloads"
          additional_params = { segment: segment }
          response = api_params('Events.getName', 'day', date, additional_params)
          results_array(response, 'nb_events')
        end

        def downloads_for_id(id, date = default_date_range)
          segment = "eventAction==Downloads;eventName==#{id}"
          additional_params = { segment: segment }
          response = api_params('Events.getAction', 'day', date, additional_params)
          results_array(response, 'nb_events')
        end

        def top_downloads(ref = 'all', date = default_date_range)
          if ref == 'all'
            additional_params = { segment: "eventCategory==Files;eventAction==Downloaded" }
            response = api_params('Events.getName', 'range', date, additional_params)

            results_array_with_ids(response, 'nb_events')
          else
            send(:top_downloads_filtered, ref, date)
          end
        end

        def top_downloads_filtered(ref, date)
          additional_params = { segment: "eventCategory==#{ref.titleize};eventAction==Downloads" }
          response = api_params('Events.getName', 'range', date, additional_params)
          results_array_with_ids(response, 'nb_events')
        end

        def downloads_for_file(file, period = 'range', date = default_date_range)
          additional_params = { segment: "eventName==#{file}" }
          response = api_params('Events.getName', period, date, additional_params)
          response.count.zero? ? 0 : response.first['nb_events'].to_i
        end

        def top_pages(ref = "collections", date = default_date_range)
          segment = "eventCategory==#{ref.titleize};eventAction==Views"
          additional_params = { segment: segment }
          response = api_params('Events.getName', 'range', date, additional_params)
          results_array_with_ids(response, 'nb_events')
        end

        def pageviews(ref = 'all', date = default_date_range)
          if ref == 'all'
            response = api_params('Actions.get', 'day', date)
            results_array(response, 'nb_pageviews')
          else
            send(:pageviews_filtered, ref, date)
          end
        end

        def pageviews_filtered(ref, date)
          additional_params = { label: ref }
          response = api_params('Actions.getPageUrls', 'day', date, additional_params)
          results_array(response, 'nb_hits')
        end

        def pageviews_for_url(url, date = default_date_range)
          additional_params = { pageUrl: url }
          response = api_params('Actions.getPageUrl', 'day', date, additional_params)
          results_array(response, 'nb_hits')
        end

        def unique_visitors(date = default_date_range)
          response = api_params('Actions.get', 'day', date)
          results_array(response, 'nb_uniq_pageviews')
        end

        def unique_visitors_for_url(url, date = default_date_range)
          additional_params = { pageUrl: url }
          response = api_params('Actions.getPageUrl', 'day', date, additional_params)
          results_array(response, 'nb_uniq_visitors')
        end

        def new_visitors(period = 'month', date = 'today')
          response = api_params('VisitFrequency.get', period, date)
          response["nb_visits_new"]
        end

        def new_visits_by_day(date = default_date_range, period = 'day')
          result = api_params('VisitFrequency.get', period, date)
          results_array(result, 'nb_visits_new')
        end

        def returning_visitors(period = 'month', date = 'today')
          response = api_params('VisitFrequency.get', period, date)
          response["nb_visits_returning"]
        end

        def returning_visits_by_day(date = default_date_range, period = 'day')
          result = api_params('VisitFrequency.get', period, date)
          results_array(result, 'nb_visits_returning')
        end

        def total_visitors(period = 'month', date = 'today')
          response = api_params('VisitFrequency.get', period, date)
          response["nb_visits_returning"].to_i + response["nb_visits_new"].to_i
        end

        def results_array(response, metric)
          results = []
          response.each do |result|
            if result[1].empty?
              results.push([result[0].to_date, 0])
            elsif result[1].is_a?(Array)
              results.push([result[0].to_date, result[1].first[metric]])
            else
              results.push([result[0].to_date, result[1][metric].presence || 0])
            end
          end
          Hyrax::Analytics::Results.new(results)
        end

        def results_array_with_ids(response, metric)
          results = []
          response.each do |result|
            results.push([result['label'], result[metric]])
          end

          results.sort_by { |el| -el[1] }
        end

        def get(params)
          response = Faraday.get(config.base_url, params)
          return [] if response.status != 200
          JSON.parse(response.body)
        end

        def api_params(method, period, date, additional_params = {})
          params = {
            module: "API",
            idSite: config.site_id,
            method: method,
            period: period,
            date: date,
            format: "JSON",
            token_auth: config.auth_token
          }
          params.merge!(additional_params)
          get(params)
        end
      end
    end
  end
end

# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Hyrax
  module Analytics
    module Matomo
      extend ActiveSupport::Concern

      # rubocop:disable Metrics/BlockLength
      class_methods do
        # Loads configuration options from config/analytics.yml. Expected structure:
        # `analytics:`
        # `  matomo:`
        # `    base_url: <%= ENV['MATOMO_BASE_URL']`
        # `    site_id: <%= ENV['MATOMO_SITE_ID']`
        # `    auth_token: <%= ENV['MATOMO_AUTH_TOKEN']`
        # @return [Config]
        def config
          @config ||= Config.load_from_yaml
        end

        class Config
          # TODO: test matomo and see if it needs any of the updates from https://github.com/samvera/hyrax/pull/6063
          def self.load_from_yaml
            filename = Rails.root.join('config', 'analytics.yml')
            yaml = YAML.safe_load(ERB.new(File.read(filename)).result)
            unless yaml
              Hyrax.logger.error("Unable to fetch any keys from #{filename}.")
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

        def default_date_range
          "#{Hyrax.config.analytics_start_date},#{Time.zone.today}"
        end

        # Returns a total count of an event action over a date range
        def total_events(action, date = default_date_range)
          additional_params = { label: action }
          response = api_params('Events.getAction', 'range', date, additional_params)
          response&.first ? response.first["nb_events"] : 0
        end

        # Returns a total count of an event action for an id over a date range
        def total_events_for_id(id, action, date = default_date_range)
          additional_params = {
            flat: 1,
            label: "#{id} - #{action}"
          }
          response = api_params('Events.getName', 'range', date, additional_params)
          response&.first ? response.first["nb_events"] : 0
        end

        def daily_events(action, date = default_date_range)
          additional_params = { label: action }
          response = api_params('Events.getAction', 'day', date, additional_params)
          results_array(response, 'nb_events')
        end

        # Pass in an action name and an id and get back the daily count of events for that id. [date, event_count]
        def daily_events_for_id(id, action, date = default_date_range)
          additional_params = {
            flat: 1,
            label: "#{id} - #{action}"
          }
          response = api_params('Events.getName', 'day', date, additional_params)
          results_array(response, 'nb_events')
        end

        #  Returns a list of the total of events by id in the format of [["id", event_count]]
        def top_events(action, date = default_date_range)
          additional_params = {
            flat: '1',
            filter_column: 'Events_EventAction',
            filter_pattern: action.to_s,
            filter_limit: '-1',
            filter_sort_column: 'nb_events',
            filter_sort_order: 'desc'
          }
          response = api_params('Events.getName', 'range', date, additional_params)
          response.map { |res| [res['Events_EventName'], res['nb_events']] }
        end

        # Filter the daily events by a specific action and get back the daily count of number of events.
        # TODO(geezy): NOT IN USE BUT SAVING FOR POTENTIAL REFACTOR
        def filter_by_action(action, response)
          results = []
          response.each do |result|
            if result[1].empty?
              results.push([result[0].to_date, 0])
            elsif result[1].is_a?(Array)
              result[1].each do |subtable|
                results.push([result[0].to_date, subtable["nb_events"].to_i]) if subtable["label"] == action
              end
            end
          end
          Hyrax::Analytics::Results.new(results)
        end

        def unique_visitors(date = default_date_range)
          response = api_params('Actions.get', 'day', date)
          results_array(response, 'nb_uniq_pageviews')
        end

        def unique_visitors_for_id(url, date = default_date_range)
          # additional_params = { pageUrl: url }
          # response = api_params('Actions.getPageUrl', 'day', date, additional_params)
          # results_array(response, 'nb_uniq_visitors')
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

        # TODO: implement
        def page_statistics(_start_date, _object)
          []
        end

        def results_array(response, metric)
          results = []
          response.each do |result|
            if result[1].empty?
              results.push([result[0].to_date, 0])
            elsif result[1].is_a?(Array)
              results.push([result[0].to_date, result[1].first[metric].to_i])
            else
              results.push([result[0].to_date, result[1][metric].presence.to_i])
            end
          end
          Hyrax::Analytics::Results.new(results)
        end

        # If Matomo detects an error it will return a reponse with the key {"result":"error"}
        # instead of returning an error status code. This method checks for that key.
        def contains_matomo_error?(response)
          response.is_a?(Hash) && response["result"] == "error"
        end

        def get(params)
          response = Faraday.get(config.base_url, params)
          return [] if response.status != 200
          api_response = JSON.parse(response.body)
          return [] if contains_matomo_error?(api_response)
          api_response
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
# rubocop:enable Metrics/ModuleLength

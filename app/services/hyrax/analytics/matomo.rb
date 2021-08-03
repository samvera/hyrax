# frozen_string_literal: true

module Hyrax
  module Analytics
    module Matomo
      extend ActiveSupport::Concern
      included do
        private_class_method :config
        private_class_method :get
        private_class_method :api_params
      end

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

        def pageviews_monthly(period, date)
          method = 'VisitsSummary.getActions'
          response = api_params(method, period, date, nil)
          response
        end

        def pageviews(period, date)
          method = 'Actions.get'
          response = api_params(method, period, date, nil)
          response['nb_pageviews']
        end

        def new_visitors(period, date)
          method = 'VisitFrequency.get'
          response = api_params(method, period, date, nil)
          response["nb_visits_new"]
        end

        def returning_visitors(period, date)
          method = 'VisitFrequency.get'
          response = api_params(method, period, date, nil)
          response["nb_visits_returning"]
        end

        def total_visitors(period, date)
          method = 'VisitFrequency.get'
          response = api_params(method, period, date, nil)
          response["nb_visits_returning"].to_i + response["nb_visits_new"].to_i
        end

        def unique_visitors(period, date)
          method = 'VisitsSummary.getUniqueVisitors'
          response = api_params(method, period, date, nil)
          response['value']
        end

        def pageviews_by_url(period, date, _url)
          method = 'Actions.getPageUrl'
          response = api_params(method, period, date, nil)
          response.count.zero? ? 0 : response.first["nb_visits"]
        end

        def get(params)
          response = Faraday.get(config.base_url, params)
          return [] if response.status != 200
          JSON.parse(response.body)
        end

        def api_params(method, period, date, url)
          params = {
            module: "API",
            idSite: config.site_id,
            method: method,
            period: period,
            date: date,
            url: url,
            format: "JSON",
            token_auth: config.auth_token
          }
          get(params)
        end
      end
    end
  end
end

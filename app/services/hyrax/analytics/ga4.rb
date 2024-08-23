# frozen_string_literal: true

require 'oauth2'

begin
  require "google/analytics/data/v1beta"
rescue LoadError
  $stderr.puts "Unable to load 'google/analytics/data/v1beta'; this is okay unless you are trying to do analytics reporting."
end

module Hyrax
  module Analytics
    # rubocop:disable Metrics/ModuleLength
    module Ga4
      extend ActiveSupport::Concern
      # rubocop:disable Metrics/BlockLength
      class_methods do
        # Loads configuration options from config/analytics.yml. You only need PRIVATE_KEY_PATH or
        # PRIVATE_KEY_VALUE. VALUE takes precedence.
        # Expected structure:
        # `analytics:`
        # `  ga4:`
        #      analytics_id: <%= ENV['GOOGLE_ANALYTICS_ID'] %>
        #      property_id: <%= ENV['GOOGLE_ANALYTICS_PROPERTY_ID'] %>
        #      account_json: <%= ENV['GOOGLE_ACCOUNT_JSON'] %>
        #      account_json_path: <%= ENV['GOOGLE_ACCOUNT_JSON_PATH'] %>
        # @return [Config]
        def config
          @config ||= Config.load_from_yaml
        end

        class Config
          def self.load_from_yaml
            filename = Rails.root.join('config', 'analytics.yml')
            yaml = YAML.safe_load(ERB.new(File.read(filename)).result)
            unless yaml
              Hyrax.logger.error("Unable to fetch any keys from #{filename}.")
              return new({})
            end
            config = yaml.fetch('analytics')&.fetch('ga4', nil)
            unless config
              Deprecation.warn("Deprecated analytics configuration format found. Please update config/analytics.yml.")
              config = yaml.fetch('analytics')
              # this has to exist here with a placeholder so it can be set in the Hyrax initializer
              # it is only for backward compatibility
              config['analytics_id'] = '-'
            end
            new config
          end

          KEYS = %w[analytics_id property_id account_json account_json_path].freeze
          REQUIRED_KEYS = %w[analytics_id property_id].freeze

          def initialize(config)
            @config = config
          end

          # @return [Boolean] are all the required values present?
          def valid?
            return false unless @config['account_json'].present? || @config['account_json_path'].present?

            REQUIRED_KEYS.all? { |required| @config[required].present? }
          end

          def base64?(value)
            value.is_a?(String) && Base64.strict_encode64(Base64.decode64(value)) == value
          end

          def account_json_string
            return @account_json_string if @account_json_string
            @account_json_string = if @config['account_json']
                                     base64?(@config['account_json']) ? Base64.decode64(@config['account_json']) : @config['account_json']
                                   else
                                     File.read(@config['account_json_path'])
                                   end
          end

          def account_info
            @account_info ||= JSON.parse(account_json_string)
          end

          KEYS.each do |key|
            # rubocop:disable Style/EvalWithLocation
            class_eval %{ def #{key}; @config.fetch('#{key}'); end }
            class_eval %{ def #{key}=(value); @config['#{key}'] = value; end }
            # rubocop:enable Style/EvalWithLocation
          end
        end

        def client
          @client ||= ::Google::Analytics::Data::V1beta::AnalyticsData::Client.new do |conf|
            conf.credentials = config.account_info
          end
        end

        def property
          "properties/#{config.property_id}"
        end

        # rubocop:disable Metrics/MethodLength
        def to_date_range(period)
          case period
          when "day"
            start_date = Time.zone.today
            end_date = Time.zone.today
          when "week"
            start_date = Time.zone.today - 7.days
            end_date = Time.zone.today
          when "month"
            start_date = Time.zone.today - 1.month
            end_date = Time.zone.today
          when "year"
            start_date = Time.zone.today - 1.year
            end_date = Time.zone.today
          end

          [start_date, end_date]
        end
        # rubocop:enable Metrics/MethodLength

        def keyword_conversion(date)
          case date
          when "last12"
            start_date = Time.zone.today - 11.months
            end_date = Time.zone.today

            [start_date, end_date]
          else
            date.split(",")
          end
        end

        def date_period(period, date)
          if period == "range"
            date.split(",")
          else
            to_date_range(period)
          end
        end

        # Configure analytics_start_date in ENV file
        def default_date_range
          "#{Hyrax.config.analytics_start_date},#{Time.zone.today + 1.day}"
        end

        # The number of events by day for an action
        def daily_events(action, date = default_date_range)
          date = date.split(",")
          EventsDaily.summary(date[0], date[1], action)
        end

        # The number of events by day for an action and ID
        def daily_events_for_id(id, action, date = default_date_range)
          date = date.split(",")
          EventsDaily.by_id(date[0], date[1], id, action)
        end

        # A list of events sorted by highest event count
        def top_events(action, date = default_date_range)
          date = date.split(",")
          Events.list(date[0], date[1], action)
        end

        def unique_visitors(date = default_date_range); end

        def unique_visitors_for_id(id, date = default_date_range); end

        def new_visitors(period = 'month', date = default_date_range)
          start_date, end_date = date_period(period, date)
          Visits.new(start_date: start_date, end_date: end_date).new_visits
        end

        def new_visits_by_day(date = default_date_range, period = 'range')
          start_date, end_date = date_period(period, date)
          VisitsDaily.new(start_date: start_date, end_date: end_date).new_visits
        end

        def returning_visitors(period = 'month', date = default_date_range)
          start_date, end_date = date_period(period, date)
          Visits.new(start_date: start_date, end_date: end_date).return_visits
        end

        def returning_visits_by_day(date = default_date_range, period = 'range')
          start_date, end_date = date_period(period, date)
          VisitsDaily.new(start_date: start_date, end_date: end_date).return_visits
        end

        def total_visitors(period = 'month', date = default_date_range)
          start_date, end_date = date_period(period, date)
          Visits.new(start_date: start_date, end_date: end_date).total_visits
        end

        def page_statistics(start_date, object)
          visits = VisitsDaily.new(start_date: start_date, end_date: Date.yesterday)
          visits.add_filter(dimension: 'contentId', values: [object.id.to_s])
          visits.total_visits
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
# rubocop:enable Metrics/ModuleLength

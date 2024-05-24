# frozen_string_literal: true

require 'oauth2'
require 'signet/oauth_2/client'

module Hyrax
  module Analytics
    # rubocop:disable Metrics/ModuleLength
    module Google
      extend ActiveSupport::Concern
      # rubocop:disable Metrics/BlockLength
      class_methods do
        # Loads configuration options from config/analytics.yml. You only need PRIVATE_KEY_PATH or
        # PRIVATE_KEY_VALUE. VALUE takes precedence.
        # Expected structure:
        # `analytics:`
        # `  google:`
        # `    app_name: <%= ENV['GOOGLE_OAUTH_APP_NAME']`
        # `    app_version: <%= ENV['GOOGLE_OAUTH_APP_VERSION']`
        # `    privkey_path: <%= ENV['GOOGLE_OAUTH_PRIVATE_KEY_PATH']`
        # `    privkey_value: <%= ENV['GOOGLE_OAUTH_PRIVATE_KEY_VALUE']`
        # `    privkey_secret: <%= ENV['GOOGLE_OAUTH_PRIVATE_KEY_SECRET']`
        # `    client_email: <%= ENV['GOOGLE_OAUTH_CLIENT_EMAIL']`
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
            config = yaml.fetch('analytics')&.fetch('google', nil)
            unless config
              Deprecation.warn("Deprecated analytics configuration format found. Please update config/analytics.yml.")
              config = yaml.fetch('analytics')
              # this has to exist here with a placeholder so it can be set in the Hyrax initializer
              # it is only for backward compatibility
              config['analytics_id'] = '-'
            end
            new config
          end

          KEYS = %w[analytics_id app_name app_version privkey_path privkey_value privkey_secret client_email].freeze
          REQUIRED_KEYS = %w[analytics_id app_name app_version privkey_secret client_email].freeze

          def initialize(config)
            @config = config
          end

          # @return [Boolean] are all the required values present?
          def valid?
            return false unless @config['privkey_value'].present? || @config['privkey_path'].present?
            REQUIRED_KEYS.all? { |required| @config[required].present? }
          end

          KEYS.each do |key|
            # rubocop:disable Style/EvalWithLocation
            class_eval %{ def #{key}; @config.fetch('#{key}'); end }
            class_eval %{ def #{key}=(value); @config['#{key}'] = value; end }
            # rubocop:enable Style/EvalWithLocation
          end
        end

        # Generate an OAuth2 token for Google Analytics
        # @return [OAuth2::AccessToken] An OAuth2 access token for GA
        def token(scope = 'https://www.googleapis.com/auth/analytics.readonly')
          access_token = auth_client(scope).fetch_access_token!
          OAuth2::AccessToken.new(oauth_client, access_token['access_token'], expires_in: access_token['expires_in'])
        end

        def oauth_client
          OAuth2::Client.new('', '', authorize_url: 'https://accounts.google.com/o/oauth2/auth',
                                     token_url: 'https://accounts.google.com/o/oauth2/token')
        end

        def auth_client(scope)
          private_key = Base64.decode64(config.privkey_value) if config.privkey_value.present?
          if private_key.blank?
            raise "Private key file for Google analytics was expected at '#{config.privkey_path}', but no file was found." unless File.exist?(config.privkey_path)

            private_key = File.read(config.privkey_path)
          end
          Signet::OAuth2::Client.new token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
                                     audience: 'https://accounts.google.com/o/oauth2/token',
                                     scope: scope,
                                     issuer: config.client_email,
                                     signing_key: OpenSSL::PKCS12.new(private_key, config.privkey_secret).key,
                                     sub: config.client_email
        end

        # Return a user object linked to a Google Analytics account
        # @return [Legato::User] A user account with GA access
        def user
          Legato::User.new(token)
        end

        # Return a Google Analytics profile matching specified ID
        # @ return [Legato::Management::Profile] A user profile associated with GA
        def profile
          return unless config.valid?
          @profile = user.profiles.detect do |profile|
            profile.web_property_id == config.analytics_id
          end
          raise 'User does not have access to this property' unless @profile
          @profile
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
          EventsDaily.summary(profile, date[0], date[1], action)
        end

        # The number of events by day for an action and ID
        def daily_events_for_id(id, action, date = default_date_range)
          date = date.split(",")
          EventsDaily.by_id(profile, date[0], date[1], id, action)
        end

        # A list of events sorted by highest event count
        def top_events(action, date = default_date_range)
          date = date.split(",")
          Events.send('list', profile, date[0], date[1], action)
        end

        def unique_visitors(date = default_date_range); end

        def unique_visitors_for_id(id, date = default_date_range); end

        def new_visitors(period = 'month', date = default_date_range)
          date = date_period(period, date)
          Visits.new_visits(profile, date[0], date[1])
        end

        def new_visits_by_day(date = default_date_range, _period = 'day')
          date = date.split(",")
          VisitsDaily.new_visits(profile, date[0], date[1])
        end

        def returning_visitors(period = 'month', date = default_date_range)
          date = date_period(period, date)
          Visits.return_visits(profile, date[0], date[1])
        end

        def returning_visits_by_day(date = default_date_range, _period = 'day')
          date = date.split(",")
          VisitsDaily.return_visits(profile, date[0], date[1])
        end

        def total_visitors(period = 'month', date = default_date_range)
          date = date_period(period, date)
          Visits.total_visits(profile, date[0], date[1])
        end

        # Hyrax::Download is sent to Hyrax::Analytics.profile as #hyrax__download
        # see Legato::ProfileMethods.method_name_from_klass
        def page_statistics(start_date, object)
          path = Rails.application.routes.url_helpers.polymorphic_path(object)
          profile = Hyrax::Analytics.profile
          unless profile
            Hyrax.logger.error("Google Analytics profile has not been established. Unable to fetch statistics.")
            return []
          end
          profile.hyrax__pageview(sort: 'date',
                                  start_date: start_date,
                                  end_date: Date.yesterday,
                                  limit: 10_000)
                 .for_path(path)
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
    # rubocop:enable Metrics/ModuleLength
  end
end

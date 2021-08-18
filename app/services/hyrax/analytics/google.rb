# frozen_string_literal: true
require 'oauth2'
require 'signet/oauth_2/client'

module Hyrax
  module Analytics
    module Google
      extend ActiveSupport::Concern

      # rubocop:disable Metrics/BlockLength
      class_methods do
        # Loads configuration options from config/analytics.yml. Expected structure:
        # `analytics:`
        # `  google:`
        # `    app_name: <%= ENV['GOOGLE_OAUTH_APP_NAME']`
        # `    app_version: <%= ENV['GOOGLE_OAUTH_APP_VERSION']`
        # `    privkey_path: <%= ENV['GOOGLE_OAUTH_PRIVATE_KEY_PATH']`
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
              Rails.logger.error("Unable to fetch any keys from #{filename}.")
              return new({})
            end
            new yaml.fetch('analytics')&.fetch('google')
          end

          REQUIRED_KEYS = %w[analytics_id app_name app_version privkey_path privkey_secret client_email].freeze

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
          raise "Private key file for Google analytics was expected at '#{config.privkey_path}', but no file was found." unless File.exist?(config.privkey_path)
          private_key = File.read(config.privkey_path)
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
          user.profiles.detect do |profile|
            profile.web_property_id == config.analytics_id
          end
        end

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
          date = [start_date, end_date]
        end

        def keyword_conversion(date)
          case date
          when "last12"
            start_date = Time.zone.today - 11.months
            end_date = Time.zone.today
            date = [start_date, end_date]
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

        def downloads(ref = 'all', date = "#{Time.zone.today - 5.years},#{Time.zone.today}")
          date = date.split(",")
          Downloads.send(ref, profile, date[0], date[1])
        end

        def top_downloads(ref = 'works', date = "#{Time.zone.today - 5.years},#{Time.zone.today}")
          date = date.split(",")
          Events.send("#{ref}_downloads", profile, date[0], date[1])
        end

        def downloads_for_file(file, date = "#{Time.zone.today - 11.months},#{Time.zone.today}")
          date = date.split(",")
          Downloads.file_downloads(profile, date[0], date[1], file)
        end

        # Filter top pages by either "works" or "collections"
        def top_pages(ref = 'works', date = "#{Time.zone.today - 5.years},#{Time.zone.today}")
          date = date.split(",")
          Events.send(ref, profile, date[0], date[1])
        end

        # Filter pageviews by either "all", "works", or "collections"
        def pageviews(ref = 'all', date = "#{Time.zone.today - 5.years},#{Time.zone.today}")
          date = date.split(",")
          Pageviews.send(ref, profile, date[0], date[1])
        end

        def pageviews_for_url(path, date = "#{Time.zone.today - 5.years},#{Time.zone.today}")
          date = date.split(",")
          path = path[/[^?]+/]
          Pageviews.page(profile, date[0], date[1], path)
        end

        def unique_visitors(date = "#{Time.zone.today - 5.years},#{Time.zone.today}"); end

        def unique_visitors_for_url(url, date = "#{Time.zone.today - 5.years},#{Time.zone.today}"); end

        def new_visitors(period = 'month', date = "#{Time.zone.today - 1.month},#{Time.zone.today}")
          date = date_period(period, date)
          Visits.new_visits(profile, date[0], date[1])
       end

        def unique_visitors_for_url(url, date = "#{Time.zone.today - 5.years},#{Time.zone.today}"); end

        def new_visitors(period = 'month', date = "#{Time.zone.today - 1.month},#{Time.zone.today}")
          date = date_period(period, date)
          Visits.total_visits(profile, date[0], date[1])
       end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end

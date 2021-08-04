# frozen_string_literal: true
require 'oauth2'
require 'signet/oauth_2/client'

module Hyrax
  module Analytics
    module Google
      extend ActiveSupport::Concern
     
      # included do
      #   private_class_method :config
      #   private_class_method :token
      #   private_class_method :user
      # end

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

          REQUIRED_KEYS = %w[app_name app_version privkey_path privkey_secret client_email].freeze

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
            profile.web_property_id == Hyrax.config.google_analytics_id
          end
        end

        def to_date_range(period)
          case period
          when "day"
            start_date = Date.today
            end_date = Date.today
          when "week"
            start_date = Date.today-7.days
            end_date = Date.today
          when "month"
            start_date = Date.today-1.month
            end_date = Date.today
          when "year"
            start_date = Date.today-1.year
            end_date = Date.today
          end
          date = "#{start_date},#{end_date}"
        end

        def keyword_conversion(date)
          case date
          when "last12"
            start_date = Date.today-11.months
            end_date = Date.today
            date = "#{start_date},#{end_date}"
          else
            date = date
          end
        end
        
        def pageviews_monthly(period = 'range', date = "#{Date.today-11.months},#{Date.today}")
          date = keyword_conversion(date)
          date = date.split(",")
          start_date = date[0]
          end_date = date[1]
          x = PageviewsMonthly.query(profile, start_date, end_date)
          y = []
          x.to_a.each do |y| 
            puts y[:month]
            puts y[:year]
            puts y[:pageviews]
          end
        end

        def pageviews(period = 'month', date = "#{Date.today-1.month},#{Date.today}")
          date = to_date_range(period) unless period == 'range'
          date = date.split(",")
          start_date = date[0]
          end_date = date[1]
          x = Pageviews.results(profile,
            :start_date => start_date,
            :end_date => end_date)
          x.count.zero? ? 0 : x.to_a.first.pageviews.to_i
        end

        def test
          # profile.web_property
          # Legato.results(profile).each {|result| p result}
          # Exit.results(profile).to_a
          Page.results(profile).each do |result| 
            p result.try(:pagePath)
            p result.try(:pageviews)
          end
          # Pageviews.results(profile).by_index_in_path_level_1.each do |result| 
          #   p result
          # end
          # Pageviews.query(profile, Date.yesterday, Date.today).each do |result|
          #   # Just print the pageviews & unique-pageviews, for example
          #   puts result.try(:pagePathLevel1)
          #   puts result.try(:pageviews)
          #   puts result.try(:uniquePageviews)
          # end
          # Pageviews.results(profile).each {|result| p result}
        end

        def works_pageviews
          Page.results(profile).works.each do |result| 
            p result.try(:pagePath)
            p result.try(:pageviews)
            p result.try(:pageTitle)
          end
        end
        
        # Date Format = "2021-01-01,2021-08-31"
        def new_visitors(period = nil, date = "#{Date.today-1.month},#{Date.today}")
          date = date.split(",")
          start_date = date[0]
          end_date = date[1]
          x = Visits.results(profile,
            :start_date => start_date,
            :end_date => end_date).to_a
          x.first.sessions.to_i
        end

        def returning_visitors(period = nil, date = "#{Date.today-1.month},#{Date.today}")
          date = date.split(",")
          start_date = date[0]
          end_date = date[1]
          x = Visits.results(profile,
            :start_date => start_date,
            :end_date => end_date).to_a 
          x.last.sessions.to_i
        end

        def total_visitors(period = nil, date = "#{Date.today-1.month},#{Date.today}")
          date = date.split(",")
          start_date = date[0]
          end_date = date[1]
          x = Visits.results(profile,
            :start_date => start_date,
            :end_date => end_date).to_a
          new_visits = x.first.sessions.to_i 
          returning_visits = x.last.sessions.to_i 
          new_visits + returning_visits
        end

        def unique_visitors(period, date); end

        def pageviews_by_url(period, date, url); end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end

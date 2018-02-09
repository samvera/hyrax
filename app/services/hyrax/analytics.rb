require 'oauth2'
require 'signet/oauth_2/client'

module Hyrax
  module Analytics
    # Loads configuration options from config/analytics.yml. Expected structure:
    # `analytics:`
    # `  app_name: GOOGLE_OAUTH_APP_NAME`
    # `  app_version: GOOGLE_OAUTH_APP_VERSION`
    # `  privkey_path: GOOGLE_OAUTH_PRIVATE_KEY_PATH`
    # `  privkey_secret: GOOGLE_OAUTH_PRIVATE_KEY_SECRET`
    # `  client_email: GOOGLE_OAUTH_CLIENT_EMAIL`
    # @return [Config]
    def self.config
      @config ||= Config.load_from_yaml
    end
    private_class_method :config

    class Config
      def self.load_from_yaml
        filename = Rails.root.join('config', 'analytics.yml')
        yaml = YAML.safe_load(File.read(filename))
        unless yaml
          Rails.logger.error("Unable to fetch any keys from #{filename}.")
          return new({})
        end
        new yaml.fetch('analytics')
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
    def self.token(scope = 'https://www.googleapis.com/auth/analytics.readonly')
      access_token = auth_client(scope).fetch_access_token!
      OAuth2::AccessToken.new(oauth_client, access_token['access_token'], expires_in: access_token['expires_in'])
    end

    def self.oauth_client
      OAuth2::Client.new('', '', authorize_url: 'https://accounts.google.com/o/oauth2/auth',
                                 token_url: 'https://accounts.google.com/o/oauth2/token')
    end

    def self.auth_client(scope)
      raise "Private key file for Google analytics was expected at '#{config.privkey_path}', but no file was found." unless File.exist?(config.privkey_path)
      private_key = File.read(config.privkey_path)
      Signet::OAuth2::Client.new token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
                                 audience: 'https://accounts.google.com/o/oauth2/token',
                                 scope: scope,
                                 issuer: config.client_email,
                                 signing_key: OpenSSL::PKCS12.new(private_key, config.privkey_secret).key,
                                 sub: config.client_email
    end

    private_class_method :token

    # Return a user object linked to a Google Analytics account
    # @return [Legato::User] A user account wit GA access
    def self.user
      Legato::User.new(token)
    end
    private_class_method :user

    # Return a Google Analytics profile matching specified ID
    # @ return [Legato::Management::Profile] A user profile associated with GA
    def self.profile
      return unless config.valid?
      user.profiles.detect do |profile|
        profile.web_property_id == Hyrax.config.google_analytics_id
      end
    end
  end
end

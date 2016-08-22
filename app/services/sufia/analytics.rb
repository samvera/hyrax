require 'oauth2'
require 'signet/oauth_2/client'
require 'legato'

module Sufia
  module Analytics
    # Loads configuration options from config/analytics.yml. Expected structure:
    # `analytics:`
    # `  app_name: GOOGLE_OAUTH_APP_NAME`
    # `  app_version: GOOGLE_OAUTH_APP_VERSION`
    # `  privkey_path: GOOGLE_OAUTH_PRIVATE_KEY_PATH`
    # `  privkey_secret: GOOGLE_OAUTH_PRIVATE_KEY_SECRET`
    # `  client_email: GOOGLE_OAUTH_CLIENT_EMAIL`
    # @return [Hash] A hash containing five keys: 'app_name', 'app_version', 'client_email', 'privkey_path', 'privkey_secret'
    def self.config
      @config ||= load_config
    end
    private_class_method :config

    def self.load_config
      filename = File.join(Rails.root, 'config', 'analytics.yml')
      yaml = YAML.load(File.read(filename))
      unless yaml
        Rails.logger.error("Unable to fetch any keys from #{filename}.")
        return
      end
      yaml.fetch('analytics')
    end
    private_class_method :load_config

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
      Signet::OAuth2::Client.new token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
                                 audience: 'https://accounts.google.com/o/oauth2/token',
                                 scope: scope,
                                 issuer: config.fetch('client_email'),
                                 signing_key: OpenSSL::PKCS12.new(File.read(config.fetch('privkey_path')), config.fetch('privkey_secret')).key,
                                 sub: config.fetch('client_email')
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
      user.profiles.detect do |profile|
        profile.web_property_id == Sufia.config.google_analytics_id
      end
    end
  end
end

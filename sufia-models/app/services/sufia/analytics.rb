require 'google/api_client'
require 'oauth2'
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
      @config ||= YAML.load(File.read(File.join(Rails.root, 'config', 'analytics.yml')))['analytics']
    end

    # Generate an OAuth2 token for Google Analytics
    # @return [OAuth2::AccessToken] An OAuth2 access token for GA
    def self.token
      scope = 'https://www.googleapis.com/auth/analytics.readonly'
      client = Google::APIClient.new(application_name: self.config['app_name'],
        application_version: self.config['app_version'])
      key = Google::APIClient::PKCS12.load_key(self.config['privkey_path'],
        self.config['privkey_secret'])
      service_account = Google::APIClient::JWTAsserter.new(self.config['client_email'], scope,
        key)
      client.authorization = service_account.authorize
      oauth_client = OAuth2::Client.new('', '', {
          authorize_url: 'https://accounts.google.com/o/oauth2/auth',
          token_url: 'https://accounts.google.com/o/oauth2/token'})
      OAuth2::AccessToken.new(oauth_client, client.authorization.access_token)
    end

    # Return a user object linked to a Google Analytics account
    # @return [Legato::User] A user account wit GA access
    def self.user
      Legato::User.new(self.token)
    end

    # Return a Google Analytics profile matching specified ID
    # @ return [Legato::Management::Profile] A user profile associated with GA
    def self.profile
      self.user.profiles.detect do |profile|
        profile.web_property_id == Sufia.config.google_analytics_id
      end
    end
  end
end

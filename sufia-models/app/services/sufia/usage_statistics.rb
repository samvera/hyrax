require 'google/api_client'
require 'oauth2'
require 'legato'

module Sufia
  module UsageStatistics
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

    # Convert query results into json for plotting in JQuery Flot
    # @param [Legato::Query] A Legato query object containing the results
    # @return [Array] An array of arrays represented in JSON: `[[1388563200000,4],[1388649600000,8],...]`
    def self.as_flot_json(ga_results)
      # Convert Legato query to hash
      results_list = ga_results.map(&:marshal_dump)
      # Results should look like: [[DATE_INT, NUM_HITS], ...]
      values = results_list.map do |result_hash|
        result_hash[:date] = Date.parse(result_hash[:date]).to_time.to_i * 1000
        result_hash[:pageviews] = result_hash[:pageviews].to_i
        result_hash.values
      end

      values.to_json
    end

    # Calculate total pageviews based on query results
    # @param [Legato::Query] A Legato query object containing the results
    # @return [Fixnum] An integer representing how many pageviews were recorded
    def self.total_pageviews(ga_results)
      ga_results.map(&:marshal_dump).reduce(0) { |total, result| total + result[:pageviews].to_i }
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

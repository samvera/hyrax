module Hyrax
  module Analytics
    class GoogleAnalytics < Hyrax::Analytics::Base
      def self.connection
        return unless config.valid?
        # an ||= to setup the GA connection using JSON
      end

      def self.unique_visitors(start_date)
        # yanked as examplar https://github.com/google/google-api-ruby-client/blob/master/samples/cli/lib/samples/analytics.rb
        dimensions = ['ga:date']
        metrics = ['ga:sessions', 'ga:users', 'ga:newUsers', 'ga:percentNewSessions',
                   'ga:sessionDuration', 'ga:avgSessionDuration']
        sort = ['ga:date']
        connection.get_ga_data("ga:#{profile_id}",
                               start_date,
                               String(Time.zone.today),
                               metrics.join(','),
                               dimensions: dimensions.join(','),
                               sort: sort.join(','))

        # Manipulate `result` to an agreed upon data structure
      end

      # Loads configuration options from config/analytics.yml. Expected structure:
      # `analytics:`
      # `  view_id: 'XXXXXXXXX'`
      # `  privkey_path: /path/to/key_file.json`
      # @return [Config]
      def self.config
        @config ||= Config.load_from_yaml
      end
      private_class_method :config
      # placeholder as example of existing code
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

        REQUIRED_KEYS = %w[privkey_path view_id].freeze

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

        # Return a Google Analytics Reporting Service
        def self.profile
          return unless config.valid?
          unless File.exist?(config.privkey_path)
            raise "Private key file for Google Analytics was expected at '#{config.privkey_path}', but no file was found."
          end
          analytics = Google::Apis::AnalyticsreportingV4::AnalyticsReportingService.new
          credentials = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: File.open(config.privkey_path))
          credentials.scope = 'https://www.googleapis.com/auth/analytics.readonly'
          analytics.authorization = credentials.fetch_access_token!({})["access_token"]
          [analytics, 'ga:' + config.view_id.to_s]
        end
      end
    end
  end
end

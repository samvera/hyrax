require 'piwik'

module Hyrax
  module Analytics
    class Matomo < Hyrax::Analytics::Base
      def self.connection
        return unless config.valid?
        # an ||= to setup Matomo
        # Piwik::PIWIK_URL = 'http://demo.piwik.org'
        # Piwik::PIWIK_TOKEN = 'anonymous'
        # site = Piwik::Site.load(config.site)
      end

      def self.unique_visitors(start_date)
        Piwik::VisitsSummary.getUniqueVisitors(idSite: config.site, period: :range, date: "#{start_date},#{Time.zone.today}")
        # Manipulate `result` to an agreed upon data structure
      end

      # BOILERPLATE CONFIG/AUTH STUFF BELOW THAT'S INCOMPLETE/TBD

      # Loads configuration options from config/analytics.yml. Expected structure:
      # `analytics:`
      # `  site: MATOMO_SITE_ID`
      # `  url: MATOMO_URL`
      # `  token: MATOMO_TOKEN`
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
    end
  end
end

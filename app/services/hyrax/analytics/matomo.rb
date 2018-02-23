require 'piwik'

module Hyrax
  module Analytics
    class Matomo < Hyrax::Analytics::Base
      REQUIRED_KEYS = %w[matomo_site_id matomo_token matomo_url].freeze

      class << self
        attr_accessor :config
      end

      def self.unique_visitors(start_date)
        Piwik::VisitsSummary.getUniqueVisitors(idSite: matomo_site_id, period: :range, date: "#{start_date},#{Time.zone.today}")
        # Manipulate `result` to an agreed upon data structure
      end

      # @return [Boolean] are all the required values present?
      def self.valid?
        config_keys = @config.keys
        REQUIRED_KEYS.all? { |required| config_keys.include?(required) }
      end

      REQUIRED_KEYS.each do |key|
        class_eval %{ def self.#{key};  @config.fetch('#{key}'); end }
      end
    end
  end
end

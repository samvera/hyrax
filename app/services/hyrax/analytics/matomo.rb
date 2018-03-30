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

      def self.page_report start_date, page_token = nil
        output = []
        end_date = Date.today
        site = Piwik::Site.load(matomo_site_id)

        # WIP
        report = site.visits.summary(
          date: "#{start_date.to_formatted_s(:db)},#{end_date.to_formatted_s(:db)}",
          # segment needs some tuning here.
          # docs: https://developer.matomo.org/api-reference/reporting-api-segmentation
          segment: filters
        )
        # A better strategy may be:
        # Piwik::Actions.getPageUrl idSite: 1, period: :range, date: '2018-02-29,2018-03-30', pageUrl: '/index'
        report['result'].each do |day|
          output << OpenStruct.new(date: day['date'],
                                   visitors: day['nb_unique_visitors'],
                                   sessions: day['nb_visits'])
        end
        output

      end

      #
      # Matomo can only get unique visitors by the month
      #
      def self.site_report start_date, page_token=nil
        output = []
        end_date = Date.today
        site = Piwik::Site.load(matomo_site_id)
        report = site.visits.summary(
          date: "#{start_date.to_formatted_s(:db)},#{end_date.to_formatted_s(:db)}"
        )
        report['result'].each do |day|
          output << OpenStruct.new(date: day['date'],
                                   visitors: day['nb_unique_visitors'],
                                   sessions: day['nb_visits'])
        end
        output
      end



      def self.include_filters(paths)
        paths.map { |p| "pageUrl==#{p}" }.join(',')
      end
      private_class_method :include_filters

      def self.exclude_filters(paths)
        paths.map { |p| "pageUrl!=#{p}*/edit" }.join(',')
      end
      private_class_method :include_filters

      def self.filters
        paths = super
        CGI.escape include_filters(paths) + ';' + exclude_filters(paths)
      end
      private_class_method :filters



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

module Hyrax
  class AdminStatsPresenter
    attr_reader :limit, :stats_filters

    def initialize(stats_filters, limit)
      @stats_filters = stats_filters
      @limit = limit
    end

    def start_date
      @start_date ||= extract_date_from_stats_filters(key: :start_date, as_of: :beginning_of_day)
    end

    def end_date
      @end_date ||= extract_date_from_stats_filters(key: :end_date, as_of: :end_of_day)
    end

    private

      def extract_date_from_stats_filters(key:, as_of:)
        return if stats_filters[key].blank?
        Time.zone.parse(stats_filters[key]).public_send(as_of)
      end

    public

    # @see Hyrax::Statistics::Depositors::Summary
    def depositors
      @depositors ||= Hyrax::Statistics::Depositors::Summary.depositors(start_date: start_date, end_date: end_date)
    end

    # @see Hyrax::Statistics::SystemStats.recent_users
    def recent_users
      @recent_users ||= Hyrax::Statistics::SystemStats.recent_users(limit: limit, start_date: start_date, end_date: end_date)
    end

    # @see Hyrax::Statistics::Works::ByDepositor
    def active_users
      @active_users ||= Hyrax::Statistics::Works::ByDepositor.query(limit: limit)
    end

    # @see Hyrax::Statistics::FileSets::ByFormat
    def top_formats
      @top_formats ||= Hyrax::Statistics::FileSets::ByFormat.query(limit: limit)
    end

    # @see Hyrax::Statistics::Works::Count
    def works_count
      @works_count ||= Hyrax::Statistics::Works::Count.by_permission(start_date: start_date, end_date: end_date)
    end

    def date_filter_string
      if start_date.blank?
        "unfiltered"
      elsif end_date.blank?
        "#{start_date.to_date.to_formatted_s(:standard)} to #{Date.current.to_formatted_s(:standard)}"
      else
        "#{start_date.to_date.to_formatted_s(:standard)} to #{end_date.to_date.to_formatted_s(:standard)}"
      end
    end
  end
end

module Sufia
  class AdminStatsPresenter
    attr_accessor :depositors, :deposit_stats
    attr_reader :limit, :start_date, :end_date, :stats_filters

    def initialize(stats_filters, limit)
      @stats_filters = stats_filters
      @start_date = stats_filters[:start_date]
      @end_date = stats_filters[:end_date]
      @limit = limit
    end

    def recent_users
      @recent_users ||= stats.recent_users
    end

    def active_users
      @active_users ||= stats.top_depositors
    end

    def top_formats
      @top_formats ||= stats.top_formats
    end

    def files_count
      @files_count ||= stats.document_by_permission
    end

    def users_count
      @users_count ||= stats.users_count
    end

    def date_filter_string
      if start_date.blank?
        "unfiltered"
      elsif end_date.blank?
        "#{start_date} to #{Date.current}"
      else
        "#{start_date} to #{end_date}"
      end
    end

    private

      def stats
        @stats ||= ::SystemStats.new(limit, start_date, end_date)
      end
  end
end

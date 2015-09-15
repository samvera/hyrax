module Sufia
  class AdminStatsPresenter
    attr_accessor :depositors, :deposit_stats
    attr_reader :users_stats, :limit

    def initialize(user_stats, limit)
      @users_stats = user_stats
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
      @files_count ||= file_stats.document_by_permission
    end

    def users_count
      @users_count ||= stats.users_count
    end

    private

      def stats
        @stats ||= ::SystemStats.new(limit, users_stats[:start_date], users_stats[:end_date])
      end

      def file_stats
        @file_stats ||= ::SystemStats.new(limit, users_stats[:file_start_date], users_stats[:file_end_date])
      end
  end
end

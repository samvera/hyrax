# frozen_string_literal: true
module Hyrax
  class AdminStatsPresenter
    attr_reader :limit, :stats_filters

    ##
    # @!attribute [rw] by_depositor
    #   @return [#query]
    # @!attribute [rw] by_format
    #   @return [#query]
    # @!attribute [rw] depositor_summary
    #   @return [#depositors]
    # @!attribute [rw] system_stats
    #   @return [#recent_users]
    # @!attribute [rw] works_counter
    #   @return [#by_permission]
    attr_accessor :by_depositor, :by_format, :depositor_summary, :system_stats,
                  :works_counter

    # Long parameter lists (especially optional) are preferred to hard-coded
    # dependencies. Further refactors may be desirable.
    #
    # rubocop:disable Metrics/ParameterLists

    ##
    # @param stats_filters     [Hash<Symbol, Object>]
    # @param limit             [FixNum]
    # @param by_depositor      [#query]
    # @param by_format         [#query]
    # @param depositor_summary [#depositors]
    # @param system_stats      [#recent_users]
    # @param works_counter     [#by_permission]
    def initialize(stats_filters, limit,
                   by_depositor:      Hyrax::Statistics::Works::ByDepositor,
                   by_format:         Hyrax::Statistics::FileSets::ByFormat,
                   depositor_summary: Hyrax::Statistics::Depositors::Summary,
                   system_stats:      Hyrax::Statistics::SystemStats,
                   works_counter:     Hyrax::Statistics::Works::Count)
      @stats_filters = stats_filters
      @limit = limit

      self.by_depositor      = by_depositor
      self.by_format         = by_format
      self.depositor_summary = depositor_summary
      self.system_stats      = system_stats
      self.works_counter     = works_counter
    end
    # rubocop:enable Metrics/ParameterLists

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
      @depositors ||=
        depositor_summary.depositors(start_date: start_date, end_date: end_date)
    end

    # @see Hyrax::Statistics::SystemStats.recent_users
    def recent_users
      @recent_users ||=
        system_stats.recent_users(limit: limit,
                                  start_date: start_date,
                                  end_date: end_date)
    end

    # @see Hyrax::Statistics::Works::ByDepositor
    def active_users
      @active_users ||= by_depositor.query(limit: limit)
    end

    # @see Hyrax::Statistics::FileSets::ByFormat
    def top_formats
      @top_formats ||= by_format.query(limit: limit)
    end

    # @see Hyrax::Statistics::Works::Count
    def works_count
      @works_count ||=
        works_counter.by_permission(start_date: start_date, end_date: end_date)
    end

    ##
    # @return [String]
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

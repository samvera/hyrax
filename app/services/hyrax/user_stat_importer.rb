# frozen_string_literal: true
module Hyrax
  # Cache work view, file view & file download stats for all users
  # this is called by 'rake hyrax:stats:user_stats'
  class UserStatImporter
    UserRecord = Struct.new("UserRecord", :id, :user_key, :last_stats_update)

    def initialize(options = {})
      if options[:verbose]
        stdout_logger = Logger.new(STDOUT)
        stdout_logger.level = Logger::INFO
        Hyrax.logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))
      end
      @logging = options[:logging]
      @delay_secs = options[:delay_secs].to_f
      @number_of_tries = options[:number_of_retries].to_i + 1
    end

    delegate :depositor_field, to: DepositSearchBuilder

    def import
      log_message('Begin import of User stats.')

      sorted_users.each do |user|
        start_date = date_since_last_cache(user)
        # this user has already been processed today continue without delay
        next if start_date.to_date >= Time.zone.today

        stats = {}

        process_files(stats, user, start_date)
        process_works(stats, user, start_date)
        create_or_update_user_stats(stats, user)
      end
      log_message('User stats import complete.')
    end

    # Returns an array of users sorted by the date of their last stats update. Users that have not been recently updated
    # will be at the top of the array.
    def sorted_users
      users = []
      ::User.find_each do |user|
        users.push(UserRecord.new(user.id, user.user_key, date_since_last_cache(user)))
      end
      users.sort_by(&:last_stats_update)
    end

    private

    def process_files(stats, user, start_date)
      file_ids_for_user(user).each do |file_id|
        file = Hyrax.query_service.find_by(id: file_id)
        view_stats = extract_stats_for(object: file, from: FileViewStat, start_date: start_date, user: user)
        stats = tally_results(view_stats, :views, stats) if view_stats.present?
        delay
        dl_stats = extract_stats_for(object: file, from: FileDownloadStat, start_date: start_date, user: user)
        stats = tally_results(dl_stats, :downloads, stats) if dl_stats.present?
        delay
      end
    end

    def process_works(stats, user, start_date)
      work_ids_for_user(user).each do |work_id|
        work = Hyrax.query_service.find_by(id: work_id)
        work_stats = extract_stats_for(object: work, from: WorkViewStat, start_date: start_date, user: user)
        stats = tally_results(work_stats, :work_views, stats) if work_stats.present?
        delay
      end
    end

    def extract_stats_for(object:, from:, start_date:, user:)
      rescue_and_retry("Retried #{from} on #{user} for #{object.class} #{object.id} too many times.") { from.statistics(object, start_date, user.id) }
    end

    def delay
      sleep @delay_secs
    end

    # This method never fails. It tries multiple times and finally logs the exception
    def rescue_and_retry(fail_message)
      Retriable.retriable(retry_options) do
        return yield
      end
    rescue StandardError => exception
      log_message fail_message
      log_message "Last exception #{exception}"
      # Without returning false, we return the results of log_message; which is true.
      false
    end

    def date_since_last_cache(user)
      last_cached_stat = UserStat.where(user_id: user.id).order(date: :asc).last

      if last_cached_stat
        last_cached_stat.date + 1.day
      else
        Hyrax.config.analytic_start_date || 1.week.ago
      end
    end

    def file_ids_for_user(user)
      ids = []
      ::FileSet.search_in_batches("#{depositor_field}:\"#{user.user_key}\"", fl: "id") do |group|
        ids.concat group.map { |doc| doc["id"] }
      end
      ids
    end

    def work_ids_for_user(user)
      ids = []
      Hyrax::SolrService.query_in_batches("#{depositor_field}:\"#{user.user_key}\"", fl: "id") do |hit|
        ids << hit.id
      end
      ids
    end

    # For each date, add the view and download counts for this file to the view & download sub-totals for that day.
    # The resulting hash will look something like this: {"2014-11-30 00:00:00 UTC" => {:views=>2, :downloads=>5},
    # "2014-12-01 00:00:00 UTC" => {:views=>4, :downloads=>4}}
    def tally_results(current_stats, stat_name, total_stats)
      current_stats.each do |stats|
        # Exclude the stats from today since it will only be a partial day's worth of data
        break if stats.date == Time.zone.today

        date_key = stats.date.to_s
        old_count = total_stats[date_key] ? total_stats[date_key].fetch(stat_name) { 0 } : 0
        new_count = old_count + stats.method(stat_name).call.to_i

        old_values = total_stats[date_key] || {}
        total_stats.store(date_key, old_values)
        total_stats[date_key].store(stat_name, new_count)
      end
      total_stats
    end

    def create_or_update_user_stats(stats, user)
      stats.each do |date_string, data|
        date = Time.zone.parse(date_string)

        user_stat = UserStat.where(user_id: user.id, date: date).first_or_initialize(user_id: user.id, date: date)

        user_stat.file_views = data.fetch(:views, 0)
        user_stat.file_downloads = data.fetch(:downloads, 0)
        user_stat.work_views = data.fetch(:work_views, 0)
        user_stat.save!
      end
    end

    def log_message(message)
      Hyrax.logger.info "#{self.class}: #{message}" if @logging
    end

    def retry_options
      { tries: @number_of_tries }
    end
  end
end

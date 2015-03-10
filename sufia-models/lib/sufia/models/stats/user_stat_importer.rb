module Sufia
  class UserStatImporter

    UserRecord = Struct.new("UserRecord", :id, :user_key, :last_stats_update)

    def initialize(options={})
      @verbose = options[:verbose]
      @logging = options[:logging]
      @delay_secs = options[:delay_secs].to_f
    end

    def import
      log_message('Begin import of User stats.')
      sorted_users.each do |user|
        start_date = date_since_last_cache(user)

        stats = {}
        file_ids_for_user(user).each do |file_id|
          view_stats = FileViewStat.statistics(file_id, start_date, user.id)
          stats = tally_results(view_stats, :views, stats)
          delay

          dl_stats = FileDownloadStat.statistics(file_id, start_date, user.id)
          stats = tally_results(dl_stats, :downloads, stats)
          delay
        end

        create_or_update_user_stats(stats, user)
      end
      log_message('User stats import complete.')
    end

    # Returns an array of users sorted by the date of their last
    # stats update. Users that have not been recently updated 
    # will be at the top of the array.
    def sorted_users
      users = []
      ::User.find_each do |user|
        users.push(UserRecord.new(user.id, user.user_key, date_since_last_cache(user)))
      end
      users.sort! {|a, b| a.last_stats_update <=> b.last_stats_update}
    end

private

    def delay 
      sleep @delay_secs
    end

    def date_since_last_cache(user)
      last_cached_stat = UserStat.where(user_id: user.id).order(date: :asc).last

      if last_cached_stat
        last_cached_stat.date + 1.day
      else
        Sufia.config.analytic_start_date
      end
    end

    def file_ids_for_user(user)
      ids = []
      ::GenericFile.find_in_batches("#{Solrizer.solr_name('depositor', :symbol)}:\"#{user.user_key}\"", fl:"id") do |group|
        ids.concat group.map { |doc| doc["id"] }
      end
      ids
    end

    # For each date, add the view and download counts for this
    # file to the view & download sub-totals for that day.
    # The resulting hash will look something like this:
    # {"2014-11-30 00:00:00 UTC" => {:views=>2, :downloads=>5},
    #  "2014-12-01 00:00:00 UTC" => {:views=>4, :downloads=>4}}
    def tally_results(file_stats, stat_name, total_stats)
      file_stats.each do |stats|
        # Exclude the stats from today since it will only be a partial day's worth of data
        break if stats.date == Date.today

        date_key = stats.date.to_s
        old_count = total_stats[date_key] ? total_stats[date_key].fetch(stat_name) { 0 } : 0
        new_count = old_count + stats.method(stat_name).call

        old_values = total_stats[date_key] || {}
        total_stats.store(date_key, old_values)
        total_stats[date_key].store(stat_name, new_count)
      end
      total_stats
    end

    def create_or_update_user_stats(stats, user)
      stats.each do |date_string, data|
        date = Time.zone.parse(date_string)

        user_stat = UserStat.where(user_id: user.id).where(date: date).first
        user_stat ||= UserStat.new(user_id: user.id, date: date)

        user_stat.file_views = data[:views] || 0
        user_stat.file_downloads = data[:downloads] || 0
        user_stat.save!
      end
    end

    def log_message(message)
      puts message if @verbose
      Rails.logger.info "#{self.class}: #{message}" if @logging
    end

  end
end

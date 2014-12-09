module Sufia
  module FileStatUtils

    def to_flots stats
      stats.map {|stat| stat.to_flot}
    end

    def convert_date date_time
      date_time.to_datetime.to_i * 1000
    end

    private

    def cached_stats(file_id, start_date, method)
      stats = self.where(file_id:file_id).order(date: :asc)
      ga_start_date = stats.size > 0 ? stats[stats.size-1].date + 1.day : start_date.to_date
      {ga_start_date: ga_start_date, cached_stats: stats.to_a }
    end

    def combined_stats file_id, start_date, object_method, ga_key, user_id=nil
      stat_cache_info = cached_stats( file_id, start_date, object_method)
      stats = stat_cache_info[:cached_stats]
      if stat_cache_info[:ga_start_date] < Date.today
        ga_stats =  ga_statistics(stat_cache_info[:ga_start_date], file_id)
        ga_stats.each do |stat|
          lstat = self.new file_id: file_id, date: stat[:date], object_method => stat[ga_key], user_id: user_id
          lstat.save unless Date.parse(stat[:date]) == Date.today
          stats << lstat
        end
      end
      stats
    end

  end
end

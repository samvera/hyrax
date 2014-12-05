module Sufia::UserUsageStats

  def stats
    @stats ||= UserStat.where(user_id: id).order(date: :asc)
  end

  def total_file_views
    stats.reduce(0) { |total, stat| total + stat.file_views }
  end

  def total_file_downloads
    stats.reduce(0) { |total, stat| total + stat.file_downloads }
  end

end

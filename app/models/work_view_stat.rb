class WorkViewStat < Sufia::Statistic
  self.cache_column = :work_views
  self.event_type = :pageviews

  def self.filter(work)
    { work_id: work.id }
  end
end

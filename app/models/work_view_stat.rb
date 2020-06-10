# frozen_string_literal: true
class WorkViewStat < Hyrax::Statistic
  self.cache_column = :work_views
  self.event_type = :pageviews

  def self.filter(work)
    { work_id: work.id }
  end
end

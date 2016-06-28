class FileViewStat < Sufia::Statistic
  self.cache_column = :views
  self.event_type = :pageviews

  def self.filter(file)
    { file_id: file.id }
  end
end

# frozen_string_literal: true
class FileViewStat < Hyrax::Statistic
  self.cache_column = :views
  self.event_type = :pageviews

  class << self
    # this is called by the parent class
    def filter(file)
      { file_id: file.id }
    end
  end
end

class Analytics::FileDownloadStat < Hyrax::Statistic
  self.cache_column = :downloads
  self.event_type = :totalEvents

  class << self
    def dimension_terms
      ['eventCategory', 'eventAction', 'eventLabel', 'date']
    end

    def metric_terms
      ['pageviews']
    end

    def filters(object)
      'ga:eventLabel==' + object.id.to_s
    end

    # this is called by the parent class
    def filter(file)
      { file_id: file.id }
    end
  end
end

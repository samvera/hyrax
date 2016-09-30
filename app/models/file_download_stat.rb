class FileDownloadStat < Sufia::Statistic
  self.cache_column = :downloads
  self.event_type = :totalEvents

  class << self
    # Sufia::Download is sent to Sufia::Analytics.profile as #sufia__download
    # see Legato::ProfileMethods.method_name_from_klass
    def ga_statistics(start_date, file)
      profile = Sufia::Analytics.profile
      unless profile
        Rails.logger.error("Google Analytics profile has not been established. Unable to fetch statistics.")
        return []
      end
      profile.sufia__download(sort: 'date',
                              start_date: start_date,
                              end_date: Date.yesterday)
             .for_file(file.id)
    end

    # this is called by the parent class
    def filter(file)
      { file_id: file.id }
    end
  end
end

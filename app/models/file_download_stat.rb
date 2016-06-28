class FileDownloadStat < Sufia::Statistic
  self.cache_column = :downloads
  self.event_type = :totalEvents

  # Sufia::Download is sent to Sufia::Analytics.profile as #sufia__download
  # see Legato::ProfileMethods.method_name_from_klass
  def self.ga_statistics(start_date, file)
    Sufia::Analytics.profile.sufia__download(sort: 'date', start_date: start_date, end_date: Date.yesterday).for_file(file.id)
  end

  def self.filter(file)
    { file_id: file.id }
  end
end

class FileDownloadStat < ActiveRecord::Base
  extend Sufia::FileStatUtils

  def to_flot
    [ self.class.convert_date(date), downloads ]
  end

  def self.statistics file_id, start_date, user_id=nil
    combined_stats file_id, start_date, :downloads, :totalEvents, user_id
  end

  # Sufia::Download is sent to Sufia::Analytics.profile as #sufia__download
  # see Legato::ProfileMethods.method_name_from_klass
  def self.ga_statistics start_date, file_id
    Sufia::Analytics.profile.sufia__download(sort: 'date', start_date: start_date, end_date: Date.yesterday).for_file(file_id)
  end

end

# frozen_string_literal: true
class FileDownloadStat < Hyrax::Statistic
  self.cache_column = :downloads
  self.event_type = :totalEvents

  class << self
    # Hyrax::Download is sent to Hyrax::Analytics.profile as #hyrax__download
    # see Legato::ProfileMethods.method_name_from_klass
    def ga_statistics(start_date, file)
      profile = Hyrax::Analytics.profile
      unless profile
        Rails.logger.error("Google Analytics profile has not been established. Unable to fetch statistics.")
        return []
      end
      profile.hyrax__analytics__google__download(sort: 'date',
                                                 start_date: start_date,
                                                 end_date: Date.yesterday,
                                                 limit: 10_000)
             .for_file(file.id)
    end

    # this is called by the parent class
    def filter(file)
      { file_id: file.id }
    end
  end
end

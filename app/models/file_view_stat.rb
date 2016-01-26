class FileViewStat < ActiveRecord::Base
  extend Sufia::FileStatUtils

  def to_flot
    [self.class.convert_date(date), views]
  end

  def self.statistics(file_id, start_date, user_id = nil)
    combined_stats file_id, start_date, :views, :pageviews, user_id
  end

  # Sufia::Download is sent to Sufia::Analytics.profile as #sufia__download
  # see Legato::ProfileMethods.method_name_from_klass
  def self.ga_statistics(start_date, file_id)
    path = Rails.application.routes.url_helpers.curation_concerns_file_set_path(file_id)
    Sufia::Analytics.profile.sufia__pageview(sort: 'date', start_date: start_date).for_path(path)
  end
end

class WorkViewStat < ActiveRecord::Base
  extend Sufia::WorkStatUtils

  def to_flot
    [self.class.convert_date(date), work_views]
  end

  def self.statistics(work_id, start_date, user_id = nil)
    combined_stats work_id, start_date, :work_views, :pageviews, user_id
  end

  # Sufia::Download is sent to Sufia::Analytics.profile as #sufia__download
  # see Legato::ProfileMethods.method_name_from_klass
  def self.ga_statistics(start_date, work_id)
    path = Rails.application.routes.url_helpers.curation_concerns_generic_work_path(work_id)

    Sufia::Analytics.profile.sufia__pageview(sort: 'date', start_date: start_date).for_path(path)
  end
end

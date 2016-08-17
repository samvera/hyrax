# This module wraps up two methods used by both WorkUsage and FileUsage
module AnalyticsDate
  # object.date_uploaded reflects the date the object was uploaded by the user
  # and therefore (if available) the date that we want to use for the stats
  # object.create_date reflects the date the file was added to Fedora. On data
  # migrated from one repository to another the created_date can be later
  # than the date the file was uploaded.
  def date_for_analytics(object)
    earliest = Sufia.config.analytic_start_date
    date_uploaded = string_to_date(object.date_uploaded)
    date_analytics = date_uploaded ? date_uploaded : object.create_date
    return date_analytics if earliest.blank?
    earliest > date_analytics ? earliest : date_analytics
  end

  def string_to_date(date_str)
    Time.zone.parse(date_str)
  rescue ArgumentError, TypeError
    nil
  end
end

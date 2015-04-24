class FileUsage

  attr_accessor :id, :created, :path, :downloads, :pageviews

  def initialize id
    file = ::GenericFile.find(id)
    user = User.where(email: file.depositor).first
    user_id = user ? user.id : nil

    self.id = id
    self.path = Sufia::Engine.routes.url_helpers.generic_file_path(id)
    self.created = date_for_analytics(file)
    self.downloads = FileDownloadStat.to_flots FileDownloadStat.statistics(id, created, user_id)
    self.pageviews = FileViewStat.to_flots FileViewStat.statistics(id, created, user_id)
  end

  # file.date_uploaded reflects the date the file was uploaded by the user 
  # and therefore (if available) the date that we want to use for the stats 
  # file.create_date reflects the date the file was added to Fedora. On data 
  # migrated from one repository to another the created_date can be later 
  # than the date the file was uploaded.
  def date_for_analytics(file) 
    earliest = Sufia.config.analytic_start_date
    date_uploaded = string_to_date file.date_uploaded
    date_analytics = date_uploaded ? date_uploaded : file.create_date
    return date_analytics if earliest.blank?
    earliest > date_analytics ? earliest : date_analytics 
  end

  def string_to_date(date_str)
    return DateTime.parse(date_str) 
  rescue ArgumentError, TypeError
    return nil
  end

  def total_downloads
    self.downloads.reduce(0) { |total, result| total + result[1].to_i }
  end

  def total_pageviews
    self.pageviews.reduce(0) { |total, result| total + result[1].to_i }
  end

  # Package data for visualization using JQuery Flot
  def to_flot
    [
      { label: "Pageviews",  data: pageviews },
      { label: "Downloads",  data: downloads }
    ]
  end
end

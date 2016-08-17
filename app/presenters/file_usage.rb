# Called by the stats controller, it finds cached file pageview data,
# and prepares it for visualization in /app/views/stats/file.html.erb
class FileUsage
  include AnalyticsDate
  attr_accessor :id, :created, :downloads, :pageviews

  def initialize(id)
    file = ::FileSet.find(id)
    user = User.find_by(email: file.depositor)
    user_id = user ? user.id : nil

    self.id = id
    self.created = date_for_analytics(file)
    self.downloads = FileDownloadStat.to_flots FileDownloadStat.statistics(file, created, user_id)
    self.pageviews = FileViewStat.to_flots FileViewStat.statistics(file, created, user_id)
  end

  def total_downloads
    downloads.reduce(0) { |total, result| total + result[1].to_i }
  end

  def total_pageviews
    pageviews.reduce(0) { |total, result| total + result[1].to_i }
  end

  # Package data for visualization using JQuery Flot
  def to_flot
    [
      { label: "Pageviews",  data: pageviews },
      { label: "Downloads",  data: downloads }
    ]
  end
end

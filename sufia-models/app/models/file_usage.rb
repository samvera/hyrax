class FileUsage

  attr_accessor :id, :created, :path, :downloads, :pageviews

  def initialize id
    self.id = id
    self.path = Sufia::Engine.routes.url_helpers.generic_file_path(Sufia::Noid.noidify(id))
    earliest = Sufia.config.analytic_start_date
    self.created = DateTime.parse(::GenericFile.find(id).create_date)
    self.created = earliest > created ? earliest : created unless earliest.blank?
    self.downloads = FileDownloadStat.to_flots FileDownloadStat.statistics(id, created)
    self.pageviews = FileViewStat.to_flots FileViewStat.statistics(id, created)
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

class FileUsage

  attr_accessor :id, :created, :path, :downloads, :pageviews

  def initialize id
    self.id = id
    self.path = Sufia::Engine.routes.url_helpers.generic_file_path(Sufia::Noid.noidify(id))
    earliest = Sufia.config.analytic_start_date
    self.created = DateTime.parse(::GenericFile.find(id).create_date)
    self.created = earliest > created ? earliest : created unless earliest.blank?
    self.downloads = download_statistics
    self.pageviews = pageview_statistics
  end

  def total_downloads
    self.downloads.map(&:marshal_dump).reduce(0) { |total, result| total + result[:totalEvents].to_i }
  end

  def total_pageviews
    self.pageviews.map(&:marshal_dump).reduce(0) { |total, result| total + result[:pageviews].to_i }
  end
  
  # Package data for visualization using JQuery Flot 
  def to_flot
    [
      { label: "Pageviews",  data: pageviews_to_flot },
      { label: "Downloads",  data: downloads_to_flot }
    ]
  end

  private

  # Sufia::Download is sent to Sufia::Analytics.profile as #sufia__download
  # see Legato::ProfileMethods.method_name_from_klass
  def download_statistics
    Sufia::Analytics.profile.sufia__download(sort: 'date', start_date: created).for_file(self.id)
  end

  # Sufia::Pageview is sent to Sufia::Analytics.profile as #sufia__pageview
  # see Legato::ProfileMethods.method_name_from_klass
  def pageview_statistics
    Sufia::Analytics.profile.sufia__pageview(sort: 'date', start_date: created).for_path(self.path)
  end

  def pageviews_to_flot values = Array.new
    self.pageviews.map(&:marshal_dump).map do |result_hash|
      values << [ (Date.parse(result_hash[:date]).to_time.to_i * 1000), result_hash[:pageviews].to_i ]
    end
    return values
  end

  def downloads_to_flot values = Array.new
    self.downloads.map(&:marshal_dump).map do |result_hash|
      values << [ (Date.parse(result_hash[:date]).to_time.to_i * 1000), result_hash[:totalEvents].to_i ]
    end
    return values
  end

end

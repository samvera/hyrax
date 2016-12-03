# Called by the stats controller, it finds cached file pageview data,
# and prepares it for visualization in /app/views/stats/file.html.erb
module Hyrax
  class FileUsage < StatsUsagePresenter
    def initialize(id)
      self.model = ::FileSet.find(id)
    end

    alias file model

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

    private

      def downloads
        to_flots(FileDownloadStat.statistics(model, created, user_id))
      end

      def pageviews
        to_flots(FileViewStat.statistics(model, created, user_id))
      end
  end
end

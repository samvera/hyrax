# frozen_string_literal: true
module Hyrax
  ##
  # Called by the stats controller, it finds cached file pageview data,
  # and prepares it for visualization in /app/views/stats/file.html.erb
  class FileUsage < StatsUsagePresenter
    def initialize(id)
      self.model = Hyrax.query_service.find_by(id: id)
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
      @downloads ||= to_flots(FileDownloadStat.statistics(model, created, user_id))
    end

    def pageviews
      @pageviews ||= to_flots(FileViewStat.statistics(model, created, user_id))
    end
  end
end

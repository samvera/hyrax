# frozen_string_literal: true

module Hyrax
  # TODO: - Analytics do we still need this?
  # Follows the model established by {FileUsage}.
  #
  # Called by the stats controller, it finds cached work pageview data,
  # and prepares it for visualization in /app/views/stats/work.html.erb
  class WorkUsage < StatsUsagePresenter
    def initialize(id)
      self.model = Hyrax.query_service.find_by(id: id)
    end

    alias work model

    def to_s
      model.title.first
    end

    def total_pageviews
      pageviews.reduce(0) { |total, result| total + result[1].to_i }
    end

    # Package data for visualization using JQuery Flot
    def to_flot
      [
        { label: "Pageviews", data: pageviews }
      ]
    end

    private

    def pageviews
      to_flots WorkViewStat.statistics(model, created, user_id)
    end
  end
end

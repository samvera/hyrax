# class WorkUsage follows the model established by FileUsage
# Called by the stats controller, it finds cached work pageview data,
# and prepares it for visualization in /app/views/stats/work.html.erb
class WorkUsage
  include AnalyticsDate
  attr_accessor :id, :created, :pageviews, :work

  def initialize(id)
    @work = CurationConcerns::WorkRelation.new.find(id)
    user = User.find_by(email: work.depositor)
    user_id = user ? user.id : nil

    self.id = id
    self.created = date_for_analytics(work)
    self.pageviews = WorkViewStat.to_flots WorkViewStat.statistics(work, created, user_id)
  end

  delegate :to_s, to: :work

  def total_pageviews
    pageviews.reduce(0) { |total, result| total + result[1].to_i }
  end

  # Package data for visualization using JQuery Flot
  def to_flot
    [
      { label: "Pageviews", data: pageviews }
    ]
  end
end

class ResolrizeJob < ActiveJob::Base
  queue_as :resolrize

  def perform
    ActiveFedora::Base.reindex_everything
  end
end

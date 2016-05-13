class ResolrizeJob < ActiveJob::Base
  def perform
    ActiveFedora::Base.reindex_everything
  end
end

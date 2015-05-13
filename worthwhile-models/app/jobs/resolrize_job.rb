class ResolrizeJob
  def queue_name
    :resolrize
  end

  def run
    ActiveFedora::Base.reindex_everything
  end
end

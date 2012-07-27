class ResolrizeJob
  @queue = :resolrize

  def self.perform
    Solrizer::Fedora::Solrizer.new.solrize_objects(:suppress_errors => false)
  end
end

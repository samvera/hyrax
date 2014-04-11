class FeaturedWork < ActiveRecord::Base
  validate :count_within_limit, on: :create
  FEATURE_LIMIT = 5

  def count_within_limit
    unless FeaturedWork.can_create_another?
      errors.add(:base, "Limited to #{FEATURE_LIMIT} featured works.")
    end
  end

  class << self
    def can_create_another?
      FeaturedWork.count < FEATURE_LIMIT
    end

    delegate :query, :construct_query_for_pids, to: ActiveFedora::SolrService

    def generic_files
      pids = pluck(:generic_file_id).map { |noid| Sufia::Noid.namespaceize(noid) }
      solr_docs = query(construct_query_for_pids(pids))
      solr_docs.map { |doc| SolrDocument.new(doc) }
    end
  end
end


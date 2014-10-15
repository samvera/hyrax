class Hydra::PermissionsSolrDocument < SolrDocument
  def under_embargo?
    #permissions = permissions_doc(params[:id])
    embargo_key = ActiveFedora::SolrService.solr_name("embargo_release_date", Hydra::Datastream::RightsMetadata.date_indexer)
    if self[embargo_key]
      embargo_date = Date.parse(self[embargo_key].split(/T/)[0])
      return embargo_date > Date.parse(Time.now.to_s)
    end
    false
  end

  def is_public?
    ActiveSupport::Deprecation.warn("Hydra::PermissionsSolrDocument.is_public? has been deprecated. Use can? instead.")
    access_key = ActiveFedora::SolrService.solr_name("access", Hydra::Datastream::RightsMetadata.indexer)
    self[access_key].present? && self[access_key].first.downcase == "public"
  end
end

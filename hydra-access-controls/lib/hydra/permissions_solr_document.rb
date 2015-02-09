class Hydra::PermissionsSolrDocument < SolrDocument

  def under_embargo?
    embargo_key = ActiveFedora::SolrService.solr_name("embargo_release_date", Hydra::Datastream::RightsMetadata.date_indexer)
    if self[embargo_key] 
      embargo_date = Date.parse(self[embargo_key].split(/T/)[0])
      return embargo_date > Date.parse(Time.now.to_s)
    end
    false
  end  

end


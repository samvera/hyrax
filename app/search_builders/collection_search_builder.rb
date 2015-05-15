class CollectionSearchBuilder < Blacklight::Solr::SearchBuilder
  include Hydra::Collections::SearchBehaviors

  def item
    scope.item
  end

  # include filters into the query to only include the collection memebers
  def include_item_ids(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "hasCollectionMember_ssim:#{item.id}"
  end

  def include_contained_files(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!join from=generic_files_tesim to=id}{!join from=hasCollectionMember_ssim to=id}id:#{collection.id}"
  end

end

# Given the id of a work, find the collections it is a member of
class ParentCollectionSearchBuilder < Hyrax::CollectionSearchBuilder
  delegate :item, to: :scope

  # include filters into the query to only include the collection memebers
  def include_item_ids(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "child_object_ids_ssim:#{item.id}"
  end
end

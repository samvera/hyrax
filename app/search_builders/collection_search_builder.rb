# Finds the child objects contained within a collection
class CollectionSearchBuilder < Hydra::SearchBuilder
  include Hydra::Collections::SearchBehaviors
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  self.from_field = 'child_object_ids_ssim'

  # This is like include_collection_ids, but it also joins the files.
  def include_contained_files(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!join from=file_set_ids_ssim to=id}{!join from=child_object_ids_ssim to=id}id:#{collection.id}"
  end
end

class CollectionSearchBuilder < Blacklight::Solr::SearchBuilder
  include Hydra::Collections::SearchBehaviors

  attr_reader :item

  # include filters into the query to only include the collection memebers
  def include_item_ids(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "hasCollectionMember_ssim:#{item.id}"
  end

  def initialize(item, processor_chain, scope)
    super(processor_chain, scope)
    @item = item
  end

end

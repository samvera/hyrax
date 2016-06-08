# Added to allow for the My controller to show only things I have edit access to
class Sufia::MyCollectionsSearchBuilder < Sufia::SearchBuilder
  include Sufia::MySearchBuilderBehavior

  self.default_processor_chain += [
    :show_only_resources_deposited_by_current_user,
    :show_only_collections
  ]

  def show_only_collections(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: Collection.to_class_uri)
    ]
  end
end

# Added to allow for the My controller to show only things I have edit access to
class Hyrax::MyHighlightsSearchBuilder < Hyrax::SearchBuilder
  include Hyrax::MySearchBuilderBehavior

  self.default_processor_chain += [:show_only_highlighted_works]

  def show_only_highlighted_works(solr_parameters)
    ids = scope.current_user.trophies.pluck(:work_id)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] += [
      ActiveFedora::SolrQueryBuilder.construct_query_for_ids(ids)
    ]
  end
end

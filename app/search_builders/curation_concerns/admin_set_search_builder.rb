module CurationConcerns
  class AdminSetSearchBuilder < ::SearchBuilder
    # This overrides the filter_models in FilterByType
    def filter_models(solr_parameters)
      solr_parameters[:fq] << ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::AdminSet.to_class_uri)
    end
  end
end

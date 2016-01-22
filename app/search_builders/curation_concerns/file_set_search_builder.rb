module CurationConcerns
  class FileSetSearchBuilder < Hydra::SearchBuilder
    include CurationConcerns::SingleResult
    self.default_processor_chain += [:only_file_sets]

    def only_file_sets(solr_parameters)
      solr_parameters[:fq] << ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::FileSet.to_class_uri)
    end
  end
end

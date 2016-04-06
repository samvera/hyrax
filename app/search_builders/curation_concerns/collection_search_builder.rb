module CurationConcerns
  class CollectionSearchBuilder < ::SearchBuilder
    # Defines which search_params_logic should be used when searching for Collections
    self.default_processor_chain = [:default_solr_parameters, :add_query_to_solr,
                                    :add_access_controls_to_solr_params, :add_collection_filter, :some_rows, :sort_by_title]

    def some_rows(solr_parameters)
      solr_parameters[:rows] = '100'
    end

    def add_collection_filter(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::Collection.to_class_uri)
    end

    # Sort results by title if no query was supplied.
    # This overrides the default 'relevance' sort.
    def sort_by_title(solr_parameters)
      return if solr_parameters[:q]
      solr_parameters[:sort] ||= "#{sort_field} asc"
    end

    attr_writer :discovery_perms

    def discovery_permissions
      @discovery_perms || super
    end

    def sort_field
      Solrizer.solr_name('title', :sortable)
    end
  end
end

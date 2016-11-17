module CurationConcerns
  class CollectionSearchBuilder < ::SearchBuilder
    include FilterByType
    # Defines which search_params_logic should be used when searching for Collections
    self.default_processor_chain = [:default_solr_parameters, :add_query_to_solr,
                                    :add_access_controls_to_solr_params, :filter_models,
                                    :some_rows, :sort_by_title]

    def some_rows(solr_parameters)
      solr_parameters[:rows] = '100'
    end

    # This overrides FilterByType and ensures we only match on collections.
    def only_collections?
      true
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

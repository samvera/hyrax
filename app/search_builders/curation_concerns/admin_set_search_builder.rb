module CurationConcerns
  class AdminSetSearchBuilder < ::SearchBuilder
    def initialize(context, access)
      @access = access
      super(context)
    end

    # This overrides the filter_models in FilterByType
    def filter_models(solr_parameters)
      solr_parameters[:fq] << ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::AdminSet.to_class_uri)
    end

    # Overrides Hydra::AccessControlsEnforcement
    def discovery_permissions
      if @access == :edit
        @discovery_permissions ||= ["edit"]
      else
        super
      end
    end
  end
end

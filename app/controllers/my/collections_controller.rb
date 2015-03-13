module My
  class CollectionsController < MyController

    self.search_params_logic += [
      :show_only_collections
    ]

    def show_only_collections(solr_parameters, user_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += [
        ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: Collection.to_class_uri)
      ]
    end

    def index
      super
      @selected_tab = :collections
    end

    protected

    def search_action_url *args
      sufia.dashboard_collections_url *args
    end
  end
end

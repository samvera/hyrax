module My
  class SharesController < MyController

    self.solr_search_params_logic += [
      :show_only_shared_files,
    ]

    def show_only_shared_files(solr_parameters, user_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += [
        "-" + ActiveFedora::SolrService.construct_query_for_rel(depositor: current_user.user_key)
      ]
    end

    def index
      super
      @selected_tab = :shared
    end
  
    protected
    
    def search_action_url *args
      sufia.dashboard_shares_url *args
    end

  end
end

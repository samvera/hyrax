module My
  class FilesController < MyController

    self.solr_search_params_logic += [
      :show_only_files_deposited_by_current_user,
      :show_only_generic_files
    ]

    def index
      super
      @selected_tab = :files
    end

    protected
    
    def search_action_url *args
      sufia.dashboard_files_url *args
    end
  
  end
end
